#!/bin/sh
set -eu

install_runtime_certs() {
    installed=0
    for f in /certs/*.crt /certs/*.pem /certs/*.cer; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        name="${name%.*}"
        cp "$f" "/usr/local/share/ca-certificates/${name}.crt"
        installed=1
    done
    if [ "$installed" -eq 1 ]; then
        update-ca-certificates >/dev/null
    fi
}

install_runtime_certs

case "${1:-}" in
    --version)
        exec pr-agent "$@"
        ;;
    ""|-h|--help)
        exec pr-agent --help
        ;;
esac

case "${1:-}" in
    http://*|https://*)
        url=$1
        shift
        set -- --pr_url "$url" "$@"
        ;;
esac

has_pr_url=0
has_issue_url=0
has_diff_mode=0
pr_url_val=""
prev=""
for arg in "$@"; do
    if [ "$prev" = "--pr_url" ]; then
        has_pr_url=1
        pr_url_val=$arg
    elif [ "$prev" = "--issue_url" ]; then
        has_issue_url=1
    elif [ "$prev" = "--diff-file" ]; then
        has_diff_mode=1
    fi
    case "$arg" in
        --pr_url=*)
            has_pr_url=1
            pr_url_val=${arg#--pr_url=}
            ;;
        --issue_url=*)
            has_issue_url=1
            ;;
        --diff-file=*)
            has_diff_mode=1
            ;;
        --stdin)
            has_diff_mode=1
            ;;
    esac
    prev=$arg
done

if [ -n "${PR_URL:-}" ] && [ "$has_pr_url" -eq 0 ]; then
    set -- --pr_url "$PR_URL" "$@"
    has_pr_url=1
    pr_url_val=$PR_URL
fi

if [ -z "${CONFIG__GIT_PROVIDER:-}" ]; then
    case "$pr_url_val" in
        http://*|https://*)
            case "$pr_url_val" in
                *github*) export CONFIG__GIT_PROVIDER=github ;;
                *gitlab*) export CONFIG__GIT_PROVIDER=gitlab ;;
                *bitbucket*) export CONFIG__GIT_PROVIDER=bitbucket ;;
                *dev.azure.com*|*visualstudio.com*) export CONFIG__GIT_PROVIDER=azure ;;
                *gitea*) export CONFIG__GIT_PROVIDER=gitea ;;
                *) ;;
            esac
            ;;
        *)
            if [ "$has_diff_mode" -eq 0 ]; then
                export CONFIG__GIT_PROVIDER=local
            fi
            ;;
    esac
fi

if [ "$has_pr_url" -eq 0 ] && [ "$has_issue_url" -eq 0 ] && [ "$has_diff_mode" -eq 0 ]; then
    if [ "${CONFIG__GIT_PROVIDER:-local}" = "local" ]; then
        if [ -n "${TARGET_BRANCH:-}" ]; then
            target_branch=$TARGET_BRANCH
        elif git -C /workspace rev-parse --verify --quiet main >/dev/null 2>&1; then
            target_branch=main
        elif git -C /workspace rev-parse --verify --quiet master >/dev/null 2>&1; then
            target_branch=master
        else
            target_branch=main
        fi
        set -- --pr_url "$target_branch" "$@"
    fi
fi

exec pr-agent "$@"
