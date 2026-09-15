# scripts

## Config

Runtime and version pins live in **[`../config`](../config)** — use **`~/config`** on the host (`ln -sf "$(pwd)/config" ~/config` after clone).

| File | Role |
|------|------|
| `~/config/env` | Secrets, airgap flags, image names (from `env.example`) |
| `~/config/versions.env` | Tool version and digest pins (for `docker build --build-arg`) |
| `~/config/pr-agent.toml` | PR-Agent settings (mounted by `pr-review`) |
| `~/config/certs/` | Optional corporate TLS roots |

Override directory: `TOOLS_CONFIG`. Override env file: `TOOLS_ENV`.

## `airgap.sh`

Wraps `docker run`: egress only to `OPENAI__API_BASE`, hardened rootfs ([ISOLATION.md](ISOLATION.md)).

## `pr-review` / `pi`

Run PR-Agent or Pi against `$PWD` with `~/config/env`.

`pi` bind-mounts host `~/.agents` (override: `PI_AGENTS_DIR`) so global skills match your local agent setup.
