# pr-agent

[PR-Agent](https://github.com/The-PR-Agent/pr-agent) image for local reviews. **Airgap** is applied by [`../scripts/airgap.sh`](../scripts/airgap.sh), not this entrypoint.

**Build** from the **repo root**. Use [`../config/versions.env`](../config/versions.env) for tags and digests (`image:tag@sha256:…` when a digest is set):

```bash
cd /path/to/tools
docker build -f pr-agent/Dockerfile \
  --build-arg PYTHON_BASE_IMAGE=python:3.12.14-slim@sha256:78387bc3881b8273120a12ebe6c1ab22b018ccc2c9adf565ae1ac9b536e184ea \
  --build-arg UV_IMAGE_REF=ghcr.io/astral-sh/uv:0.12.15@sha256:62f8c047d0a0e9ece6b53fc63df902585a67a47a7f318ddec4a37db586edc8e3 \
  --build-arg PR_AGENT_REF=v0.45.0 \
  -t tools-pr-agent:local \
  .
```

Optional: `--build-arg CA_CERT=corp-root.crt` when the file is in `config/certs/`.

Hardening: [../scripts/ISOLATION.md](../scripts/ISOLATION.md).

**Run:** `pr-review main review` or:

```bash
../scripts/airgap.sh docker run --rm --env-file ~/config/env \
  -v "$PWD:/workspace" -v "$HOME/config/pr-agent.toml:/config/config.toml:ro" \
  tools-pr-agent:local --pr_url main review
```

Config: [`../config/`](../config/README.md).
