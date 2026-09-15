# syntax=docker/dockerfile:1
# Build from repo root — see pr-agent/README.md and config/versions.env
ARG PYTHON_BASE_IMAGE=python:3.12.14-slim
FROM ${PYTHON_BASE_IMAGE}

ARG UV_IMAGE_REF=ghcr.io/astral-sh/uv:0.12.15
COPY --from=${UV_IMAGE_REF} /uv /uvx /bin/

RUN apt-get update \
    && apt-get install --no-install-recommends -y git ca-certificates iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG PR_AGENT_REPO=https://github.com/The-PR-Agent/pr-agent.git
ARG PR_AGENT_REF=v0.45.0
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
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp

RUN --mount=type=bind,source=config/certs,target=/build-certs,readonly \
    if [ -n "${CA_CERT}" ]; then \
      if [ ! -f "/build-certs/${CA_CERT}" ]; then \
        echo "CA_CERT not found in config/certs/: ${CA_CERT}" >&2; \
        exit 1; \
      fi; \
      cp "/build-certs/${CA_CERT}" /usr/local/share/ca-certificates/custom-ca.crt; \
      update-ca-certificates; \
    fi

RUN git clone --depth 1 --branch "${PR_AGENT_REF}" "${PR_AGENT_REPO}" /app \
    && uv sync --frozen --no-dev \
    && ln -sf /app/.venv/bin/pr-agent /usr/local/bin/pr-agent \
    && rm -rf /app/.git \
    && chmod -R a+rX /app

COPY config/pr-agent.toml /config/config.toml
COPY pr-agent/entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh \
    && chmod -R a+rX /config \
    && mkdir -p /workspace /certs \
    && chmod 1777 /workspace

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--help"]
