FROM smallstep/step-ca:0.14.4 AS ca

FROM smallstep/step-cli:0.14.4

# We need root access to bind port 443
USER root

RUN apk update --no-cache && \
    apk add jq

ENV CONFIG_FILE="/home/step/config/ca.json"
ENV PASSWORD_FILE="/home/step/secrets/password"

COPY entrypoint.sh /usr/local/src/entrypoint.sh

COPY --chown=step:step --from=ca /usr/local/bin/step-ca /usr/local/bin/step-ca

ENTRYPOINT ["/usr/local/src/entrypoint.sh"]

CMD exec /bin/sh -c "/usr/local/bin/step-ca --password-file $PASSWORD_FILE $CONFIG_FILE"