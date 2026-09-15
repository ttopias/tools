# syntax=docker/dockerfile:1
# Build from repo root — see pi-sandbox/README.md and config/versions.env
ARG NODE_BASE_IMAGE=node:22-bookworm-slim
FROM ${NODE_BASE_IMAGE}

ARG PI_VERSION=0.85.1
ARG CDXGEN_VERSION=12.8.4
ARG GO_VERSION=1.27.1
ARG GOLANGCI_LINT_VERSION=2.13.2
ARG SYFT_VERSION=1.51.1
ARG CA_CERT=
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NODE_USE_SYSTEM_CA=1 \
    NODE_OPTIONS=--use-system-ca \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp \
    NPM_CONFIG_CACHE=/tmp/npm-cache \
    GOPATH=/tmp/go \
    GOCACHE=/tmp/go-cache \
    PATH=/usr/local/go/bin:/usr/local/bin:/tmp/go/bin:${PATH}

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates curl git iptables \
        build-essential g++ gcc cmake pkg-config make \
        python3 python3-pip python3-venv \
        jq ripgrep fd-find unzip wget \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,source=config/certs,target=/build-certs,readonly \
    if [ -n "${CA_CERT}" ]; then \
      if [ ! -f "/build-certs/${CA_CERT}" ]; then \
        echo "CA_CERT not found in config/certs/: ${CA_CERT}" >&2; \
        exit 1; \
      fi; \
      cp "/build-certs/${CA_CERT}" /usr/local/share/ca-certificates/custom-ca.crt; \
      update-ca-certificates; \
    fi

RUN ARCH="${TARGETARCH:-amd64}" \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
      | tar -C /usr/local -xzf - \
    && GOBIN=/usr/local/bin go install "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v${GOLANGCI_LINT_VERSION}" \
    && curl -fsSL "https://raw.githubusercontent.com/anchore/syft/main/install.sh" \
      | sh -s -- -b /usr/local/bin "v${SYFT_VERSION}" \
    && npm install -g --ignore-scripts \
        "@earendil-works/pi-coding-agent@${PI_VERSION}" \
        "@cyclonedx/cdxgen@${CDXGEN_VERSION}" \
    && pi --version \
    && go version \
    && golangci-lint version \
    && syft version \
    && cdxgen --version \
    && npm cache clean --force \
    && rm -rf /root/.npm /tmp/npm-cache

COPY pi-sandbox/entrypoint.sh /entrypoint.sh
RUN chmod a+rx /entrypoint.sh \
    && mkdir -p /workspace /certs /tmp/go /tmp/go-cache \
    && chmod 1777 /workspace /tmp/go /tmp/go-cache

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["pi"]
