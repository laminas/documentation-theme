FROM alpine:3.11.2

RUN apk upgrade --no-cache \
  && apk add --no-cache \
    bash \
    git \
    openssh-client \
    ca-certificates \
    python3 \
    python3-dev \
    php7 \
    php7-fileinfo \
  && pip3 install --no-cache-dir --upgrade pip \
  && rm -rf /var/cache/* \
  && rm -rf /root/.cache/*

RUN cd /usr/bin \
  && ln -sf python3 python \
  && ln -sf pip3 pip

RUN pip install mkdocs pyaml pymdown-extensions markdown-fenced-code-tabs

COPY entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
