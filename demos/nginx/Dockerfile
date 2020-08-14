FROM smallstep/step-cli:0.14.6 as BASE

FROM nginx:1.19.2

COPY --from=BASE /usr/local/bin/step /usr/local/bin/

RUN apt-get update -qqy && \
    apt-get install -y ca-certificates curl iputils-ping

RUN mkdir -p /usr/local/share/ca-certificates

RUN mkdir -p /acme-certificates \
    && chmod 700 /acme-certificates

COPY entrypoint.sh /usr/local/src/entrypoint.sh

RUN chmod 700 /usr/local/src/entrypoint.sh

COPY helloworld.conf /etc/nginx/conf.d/

WORKDIR /acme-certificates

ENTRYPOINT [ "/usr/local/src/entrypoint.sh" ]
