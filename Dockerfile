ARG VERSION

FROM smallstep/step-ca:$VERSION

USER root

RUN apk update --no-cache && \
    apk add jq libcap

ENV CONFIG_FILE="/home/step/config/ca.json"
ENV PASSWORD_FILE="/home/step/secrets/password"

COPY entrypoint.sh /usr/local/src/entrypoint.sh

RUN chown step:step /usr/local/src/entrypoint.sh && \
    chmod 700 /usr/local/src/entrypoint.sh

RUN chown step:step /usr/local/bin/step-ca && \
    chown step:step /usr/local/bin/step && \
    chmod 700 /usr/local/bin/step-ca && \
    chmod 700 /usr/local/bin/step

USER step

ENTRYPOINT ["/usr/local/src/entrypoint.sh"]
