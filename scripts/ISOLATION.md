# Isolation model

AI tools run as **ephemeral containers** via `airgap.sh`. The **project directory** is mounted read/write; the **container root filesystem** stays read-only when hardening is on (default).

## Defaults (`AIRGAP_HARDEN=1`)

| Control | Effect |
|--------|--------|
| `--cap-drop=ALL` + `NET_ADMIN` | Only network admin for iptables airgap |
| `no-new-privileges` | Blocks privilege escalation |
| `--read-only` | Rootfs not writable; use mounted volumes + `/tmp` |
| `--tmpfs /tmp`, `/run` | Writable scratch (caches, CA bundle merge) |
| `--user $(id -u):$(id -g)` | Matches host ownership on mounted workspace |

Mount **only** the repo (or sandbox workspace), never `$HOME`, `~/.ssh`, or `docker.sock`.

## Runtime policy

- **Pin images:** `PR_AGENT_IMAGE=name@sha256:…` after you trust a build (`docker inspect --format='{{index .RepoDigests 0}}' …`).
- **API keys:** Short-lived keys on the company gateway; rotate via `~/config/env` only.
- **`AIRGAP=0`:** Break-glass only; wrappers print a warning.

## Stronger runtimes (optional)

### Rootless Docker

Run the Docker daemon in rootless mode so a container breakout does not immediately yield host root. Compatible with `airgap.sh` as long as `iptables` and `NET_ADMIN` work in your rootless setup (verify on your distro).

### gVisor (`runsc`)

```bash
# Install runsc and register runtime with Docker, then:
export DOCKER_RUNTIME=runsc
./airgap.sh docker run …
```

Adds a user-space kernel boundary; some syscalls/network paths differ — test your tool images (PR-Agent, pi-sandbox) before standardizing.

## Residual risk

- **Bind-mounted workspace** is writable on the host.
- **Prompt content** can still leave via `OPENAI__API_BASE`.
- **Docker** remains the trust boundary; do not mount the daemon socket.
