# scripts

## `airgap.sh`

Wraps `docker run`; egress allowed only to `OPENAI__API_BASE` (via `--env-file` / `-e`):

```bash
./airgap.sh docker run --rm --env-file ~/.config/pr-review/env -v "$PWD:/workspace" IMAGE [CMD...]
```

Image needs **iptables**. Set `AIRGAP=0` to skip lockdown.

## `pr-review`

PR-Agent wrapper (uses `airgap.sh` internally):

```bash
export PATH="/path/to/tools/scripts:$PATH"
cp env.example ~/.config/pr-review/env && chmod 600 ~/.config/pr-review/env
pr-review --build
cd your-repo && pr-review main review
```
