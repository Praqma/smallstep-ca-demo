#!/bin/bash

set -euo pipefail

step ca bootstrap --ca-url "${CERT_AUTH}:${CERT_AUTH_PORT}" --fingerprint "${FINGERPRINT}" --install
unset "FINGERPRINT"

update-ca-certificates

# Todo parse and check status
curl -sS "${CERT_AUTH}:${CERT_AUTH_PORT}/health"

if [[ ! -f "/acme-certificates/${SERVER_PROXY_NAME}.crt" && ! -f "/acme-certificates/${SERVER_PROXY_NAME}.key" ]]; then
    # Generate the certificate and key file for nginx
    step ca certificate "${SERVER_PROXY_NAME}" "${SERVER_PROXY_NAME}".crt "${SERVER_PROXY_NAME}".key --provisioner "${CERT_AUTH_PROVISIONER}"
fi

# Run Nginx in background
exec nginx -g "daemon off;" &

# Run the renewal daemon with default values and have it reload nginx if necessary
step ca renew --daemon --exec "nginx -s reload" "${SERVER_PROXY_NAME}".crt "${SERVER_PROXY_NAME}".key