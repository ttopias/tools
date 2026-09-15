#!/bin/sh
set -eu

install_runtime_certs() {
    bundle=/tmp/ca-bundle.crt
    cp /etc/ssl/certs/ca-certificates.crt "$bundle"
    found=0
    for f in /certs/*.crt /certs/*.pem /certs/*.cer; do
        [ -f "$f" ] || continue
        cat "$f" >>"$bundle"
        found=1
    done
    if [ "$found" -eq 1 ]; then
        export SSL_CERT_FILE=$bundle
        export REQUESTS_CA_BUNDLE=$bundle
        export CURL_CA_BUNDLE=$bundle
        export GIT_SSL_CAINFO=$bundle
        export NODE_EXTRA_CA_CERTS=$bundle
    fi
}

install_runtime_certs

if [ "$#" -eq 0 ]; then
    exec pi
fi

exec "$@"
