# tools

Local AI dev tools (air-gapped Docker).

| Directory | Role |
|-----------|------|
| [config](config) | Versions, `env.example`, PR-Agent TOML — expected at **`~/config`** at runtime |
| [pr-agent](pr-agent) | PR-Agent image |
| [pi-sandbox](pi-sandbox) | Pi agent + dev/SBOM toolchain |
| [scripts](scripts) | `airgap.sh`, `pr-review`, `pi` |

## Setup

```bash
git clone …/tools && cd tools
ln -sf "$(pwd)/config" ~/config
cp ~/config/env.example ~/config/env && chmod 600 ~/config/env
export PATH="$(pwd)/scripts:$PATH"

# Edit ~/config/env (API URL, keys). Build images — see pr-agent/README.md and pi-sandbox/README.md
# (pins in ~/config/versions.env).

cd your-repo && pr-review main review
# or: pi
```

See [config/README.md](config/README.md).
