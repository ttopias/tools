# pr-agent

[PR-Agent](https://github.com/The-PR-Agent/pr-agent) image for local reviews. **Airgap** is applied by [`../scripts/airgap.sh`](../scripts/airgap.sh), not this entrypoint.

**Build:** `docker build -t tools-pr-agent:local .` — optional `CA_CERT=corp.crt` build-arg.

**Run:** `pr-review main review` or:

```bash
../scripts/airgap.sh docker run --rm --env-file ~/.config/pr-review/env \
  -v "$PWD:/workspace" -v "$(pwd)/config.toml:/config/config.toml:ro" \
  tools-pr-agent:local --pr_url main review
```

Config: [`../scripts/env.example`](../scripts/env.example).
