# config

Single place to maintain tool versions and runtime settings. Wrappers expect this tree at **`~/config`** on the machine that runs Docker.

## Setup

```bash
# From the cloned tools repo (symlink keeps repo and ~/config in sync):
ln -sf "$(pwd)/config" ~/config

cp ~/config/env.example ~/config/env
chmod 600 ~/config/env
# Edit env: API base, keys, image names
```

Optional corporate roots: `~/config/certs/*.crt`

## Files

| File | Purpose |
|------|---------|
| [`env.example`](env.example) | Template → copy to `~/config/env` (secrets, airgap, image refs) |
| [`versions.env`](versions.env) | Pinned upstream versions, base-image digests, local image tags |
| [`pr-agent.toml`](pr-agent.toml) | PR-Agent behavior; mounted into the container by `pr-review` |
| `certs/` | Runtime TLS extras (not committed; add corp roots locally) |

Build images with `docker build` from the repo root; pass `--build-arg` values from `versions.env` (see [pr-agent/README.md](../pr-agent/README.md) and [pi-sandbox/README.md](../pi-sandbox/README.md)).

After building, record digests in `versions.env` (`*_IMAGE_DIGEST`) and set `PR_AGENT_IMAGE` / `PI_SANDBOX_IMAGE` in `env` to `name@sha256:…`.
