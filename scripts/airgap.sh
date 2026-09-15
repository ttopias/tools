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
                if [ "${OPENAI__API_BASE#http://}" != "$OPENAI__API_BASE" ]; then
                    port=80
                else
                    port=443
                fi
                ;;
        esac
        ips=$(getent ahosts "$host" | awk '{print $1}' | sort -u)
        [ -n "$ips" ] || {
            echo "airgap: could not resolve $host" >&2
            exit 1
        }

        airgap_allow_api() {
            local table_cmd=$1 cidr_suffix=$2
            $table_cmd -F OUTPUT 2>/dev/null || {
                echo "airgap: need --cap-add=NET_ADMIN ($table_cmd)" >&2
                exit 1
            }
            $table_cmd -P OUTPUT DROP
            $table_cmd -A OUTPUT -o lo -j ACCEPT
            $table_cmd -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            $table_cmd -A OUTPUT -d 127.0.0.11/32 -p udp --dport 53 -j ACCEPT
            $table_cmd -A OUTPUT -d 127.0.0.11/32 -p tcp --dport 53 -j ACCEPT
            while IFS= read -r ip; do
                [ -n "$ip" ] || continue
                $table_cmd -A OUTPUT -d "${ip}${cidr_suffix}" -p tcp --dport "$port" -j ACCEPT
            done
        }

        v4_ips=
        v6_ips=
        while IFS= read -r ip; do
            [ -n "$ip" ] || continue
            case "$ip" in
                *:*) v6_ips=${v6_ips:+$v6_ips$'\n'}$ip ;;
                *) v4_ips=${v4_ips:+$v4_ips$'\n'}$ip ;;
            esac
        done <<<"$ips"

        if [ -n "$v4_ips" ]; then
            airgap_allow_api iptables /32 <<<"$v4_ips"
        fi
        if [ -n "$v6_ips" ] && command -v ip6tables >/dev/null 2>&1; then
            airgap_allow_api ip6tables /128 <<<"$v6_ips"
        fi
        if [ -z "$v4_ips" ] && { [ -z "$v6_ips" ] || ! command -v ip6tables >/dev/null 2>&1; }; then
            echo "airgap: no usable addresses for $host (need IPv4 or ip6tables for IPv6)" >&2
            exit 1
        fi
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

if [ "${AIRGAP:-1}" = 0 ]; then
    echo "airgap: WARNING — AIRGAP=0 disables egress lockdown (break-glass only)" >&2
fi

flags=()
while [ $# -gt 0 ] && [ "${1#-}" != "$1" ]; do
    case "$1" in
        -e | --env | -v | --volume | --env-file | -w | --workdir | -p | --publish | --mount | --name | --runtime)
            flags+=("$1" "$2")
            shift 2
            ;;
        --env-file=* | --mount=* | -v=* | -w=* | -p=* | --runtime=*)
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

harden=()
if [ "${AIRGAP_HARDEN:-1}" != 0 ]; then
    uid_gid="${AIRGAP_USER:-$(id -u):$(id -g)}"
    harden=(
        --cap-drop=ALL
        --cap-add=NET_ADMIN
        --security-opt no-new-privileges:true
        --read-only
        --tmpfs /tmp:rw,nosuid,size=512m
        --tmpfs /run:rw,nosuid,size=64m
    )
    if [ "$uid_gid" != root ] && [ "$uid_gid" != 0:0 ]; then
        harden+=(--user "$uid_gid")
        # Docker sets HOME=/ for --user; keep caches on read-only rootfs tmpfs.
        harden+=(
            -e HOME=/tmp
            -e XDG_CACHE_HOME=/tmp
        )
    fi
fi

runtime=()
if [ -n "${DOCKER_RUNTIME:-}" ]; then
    runtime=(--runtime "$DOCKER_RUNTIME")
fi

# Bash 3.2 (macOS): empty arrays are errors with set -u unless guarded.
exec docker run \
    ${runtime+"${runtime[@]}"} \
    ${harden+"${harden[@]}"} \
    -v "$SELF:/usr/local/bin/airgap-entry:ro" \
    --entrypoint /usr/local/bin/airgap-entry \
    -e AIRGAP_CONTAINER=1 \
    -e "AIRGAP_EP=$(docker inspect -f '{{join .Config.Entrypoint " "}}' "$image" 2>/dev/null || true)" \
    -e "AIRGAP_CMD=$(docker inspect -f '{{join .Config.Cmd " "}}' "$image" 2>/dev/null || true)" \
    ${flags+"${flags[@]}"} "$image" "$@"
