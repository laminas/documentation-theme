FROM alpine:3.11.2

RUN apk add --no-cache \
    bash \
    git \
    openssh-client \
    ca-certificates \
    python \
    php7 \
    php7-fileinfo

RUN pip install mkdocs pyaml pymdown-extensions markdown-fenced-code-tabs

COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
