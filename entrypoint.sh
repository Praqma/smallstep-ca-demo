#!/bin/sh

export DEFAULT_CERT_VALIDITY=${DEFAULT_CERT_VALIDITY-"720h"}
export MAX_CERT_VALIDITY=${MAX_CERT_VALIDITY-"2160h"}
export DNS_NAMES=${DNS_NAMES-"localhost"}
export PASSWORD_FILE=${PASSWORD_FILE-"/home/step/secrets/password"}
export PASSWORD=${PASSWORD-"password"}
export CONFIG_FILE=${CONFIG_FILE-"/home/step/config/ca.json"}


if [ ! -f "${PASSWORD_FILE}" ]; then
  mkdir -p $(dirname $PASSWORD_FILE)
  echo $PASSWORD > $PASSWORD_FILE
fi

if [ -f "${CONFIG_FILE}" ]; then
  echo "Using existing configuration file"
else
  echo "No configuration file found at ${CONFIG_FILE}"

  /usr/local/bin/step ca init --name "Default Internal Authority" --provisioner admin --dns "${DNS_NAMES}" --address ":8443" --password-file=${PASSWORD_FILE}

  /usr/local/bin/step ca provisioner add acme --type ACME

  # Set certificate validity period
  echo $(cat config/ca.json | jq --arg DEFAULT_CERT_VALIDITY "$DEFAULT_CERT_VALIDITY" --arg MAX_CERT_VALIDITY "$MAX_CERT_VALIDITY" -r '
                                .authority.provisioners[[.authority.provisioners[] 
                                | .name=="acme"] 
                                | index(true)].claims 
                                |= (. + {"maxTLSCertDuration":$MAX_CERT_VALIDITY,"defaultTLSCertDuration":$DEFAULT_CERT_VALIDITY})') > config/ca.json
fi

exec /bin/sh -c "/usr/local/bin/step-ca --password-file $PASSWORD_FILE $CONFIG_FILE"

