#!/bin/bash

set -e

step ca bootstrap --ca-url "${CERT_AUTH}:${CERT_AUTH_PORT}" --fingerprint "${FINGERPRINT}" --install --force

update-ca-certificates

# Todo: parse and check ok else exit...
curl -sS "${CERT_AUTH}:${CERT_AUTH_PORT}/health"

# Just pass all commands to original entyrpoint.sh script
./entrypoint.sh "$@"
