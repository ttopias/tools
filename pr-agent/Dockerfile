# syntax=docker/dockerfile:1
FROM python:3.12.14-slim

COPY --from=ghcr.io/astral-sh/uv:0.9.7 /uv /uvx /bin/

RUN apt-get update \
    && apt-get install --no-install-recommends -y git ca-certificates iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG PR_AGENT_REPO=https://github.com/The-PR-Agent/pr-agent.git
ARG PR_AGENT_REF=v0.45.0
# Optional: path to a PEM/CRT in the build context (e.g. corp-root.crt).
ARG CA_CERT=

WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:${PATH}" \
    PYTHONPATH=/app \
    PR_AGENT_EXTRA_CONFIG_URL=/config/config.toml \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt

RUN --mount=type=bind,source=.,target=/src \
    if [ -n "${CA_CERT}" ]; then \
      if [ ! -f "/src/${CA_CERT}" ]; then \
        echo "CA_CERT not found in build context: ${CA_CERT}" >&2; \
        exit 1; \
      fi; \
      cp "/src/${CA_CERT}" /usr/local/share/ca-certificates/custom-ca.crt; \
      update-ca-certificates; \
    fi

RUN git clone --depth 1 --branch "${PR_AGENT_REF}" "${PR_AGENT_REPO}" /app \
    && uv sync --frozen --no-dev \
    && ln -sf /app/.venv/bin/pr-agent /usr/local/bin/pr-agent \
    && rm -rf /app/.git

COPY config.toml /config/config.toml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && mkdir -p /workspace /certs

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
