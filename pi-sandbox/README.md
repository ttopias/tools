# pi-sandbox

Air-gapped dev sandbox: [@earendil-works/pi-coding-agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent) plus Go, C++, golangci-lint, Syft, and CycloneDX cdxgen.

**Build** from the **repo root** ([`../config/versions.env`](../config/versions.env)):

```bash
cd /path/to/tools
docker build -f pi-sandbox/Dockerfile \
  --build-arg NODE_BASE_IMAGE=node:22-bookworm-slim@sha256:83f487e0a63425e5b4d146fb5e5be574bcbe1b7b843d3ebafdd95eaf7767a7e5 \
  --build-arg PI_VERSION=0.85.1 \
  --build-arg CDXGEN_VERSION=12.8.4 \
  --build-arg GO_VERSION=1.27.1 \
  --build-arg GOLANGCI_LINT_VERSION=2.13.2 \
  --build-arg SYFT_VERSION=1.51.1 \
  -t tools-pi-sandbox:local \
  .
```

Optional: `--build-arg CA_CERT=corp-root.crt` when the file is in `config/certs/`.

**Run:** [`../scripts/pi`](../scripts/pi) with [`~/config/env`](../config/env.example). Isolation: [../scripts/ISOLATION.md](../scripts/ISOLATION.md).

Node trusts corporate CAs via `NODE_USE_SYSTEM_CA` / `NODE_OPTIONS=--use-system-ca`.
