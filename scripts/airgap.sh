#!/usr/bin/env bash
# ./airgap.sh docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
set -euo pipefail

SELF="$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# --- container entrypoint (same file, mounted read-only) ----------------------
if [ "${AIRGAP_CONTAINER:-0}" = 1 ]; then
    if [ "${AIRGAP:-1}" != 0 ]; then
        [ -n "${OPENAI__API_BASE:-}" ] || {
            echo "airgap: OPENAI__API_BASE must be set" >&2
            exit 1
        }
        command -v iptables >/dev/null 2>&1 || {
            echo "airgap: iptables not found" >&2
            exit 1
        }
        rest=${OPENAI__API_BASE#*://}
        hostport=${rest%%/*}
        case "$hostport" in
            *:*) host=${hostport%:*}; port=${hostport##*:} ;;
            *)
                host=$hostport
                port=$([ "${OPENAI__API_BASE#http://}" != "$OPENAI__API_BASE" ] && echo 80 || echo 443)
                ;;
        esac
        ips=$(getent ahosts "$host" | awk '{print $1}' | sort -u)
        [ -n "$ips" ] || {
            echo "airgap: could not resolve $host" >&2
            exit 1
        }

        iptables -F OUTPUT 2>/dev/null || {
            echo "airgap: need --cap-add=NET_ADMIN" >&2
            exit 1
        }
        iptables -P OUTPUT DROP
        iptables -A OUTPUT -o lo -j ACCEPT
        iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A OUTPUT -d 127.0.0.11/32 -p udp --dport 53 -j ACCEPT
        iptables -A OUTPUT -d 127.0.0.11/32 -p tcp --dport 53 -j ACCEPT
        while IFS= read -r ip; do
            [ -n "$ip" ] && iptables -A OUTPUT -d "$ip/32" -p tcp --dport "$port" -j ACCEPT
        done <<<"$ips"
    fi

    if [ "$#" -gt 0 ]; then
        [ -n "${AIRGAP_EP:-}" ] && exec ${AIRGAP_EP} "$@"
        exec "$@"
    fi
    [ -n "${AIRGAP_EP:-}${AIRGAP_CMD:-}" ] && exec ${AIRGAP_EP} ${AIRGAP_CMD}
    echo "airgap: no command" >&2
    exit 1
fi

# --- host: wrap docker run ----------------------------------------------------
[ "${1:-}" = docker ] && [ "${2:-}" = run ] || {
    echo "Usage: airgap.sh docker run [OPTIONS] IMAGE [COMMAND] [ARG...]" >&2
    exit 1
}
shift 2

flags=()
while [ $# -gt 0 ] && [ "${1#-}" != "$1" ]; do
    case "$1" in
        -e | --env | -v | --volume | --env-file | -w | --workdir | -p | --publish | --mount | --name)
            flags+=("$1" "$2")
            shift 2
            ;;
        --env-file=* | --mount=* | -v=* | -w=* | -p=*)
            flags+=("$1")
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            flags+=("$1")
            shift
            ;;
    esac
done

image=${1:?airgap: IMAGE required}
shift

exec docker run --cap-add=NET_ADMIN \
    -v "$SELF:/usr/local/bin/airgap-entry:ro" \
    --entrypoint /usr/local/bin/airgap-entry \
    -e AIRGAP_CONTAINER=1 \
    -e "AIRGAP_EP=$(docker inspect -f '{{join .Config.Entrypoint " "}}' "$image" 2>/dev/null || true)" \
    -e "AIRGAP_CMD=$(docker inspect -f '{{join .Config.Cmd " "}}' "$image" 2>/dev/null || true)" \
    "${flags[@]}" "$image" "$@"
