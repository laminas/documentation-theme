FROM alpine:3.11.2

RUN apk update \
  && apk upgrade --no-cache \
  && apk add --no-cache \
    bash \
    git \
    openssh-client \
    ca-certificates \
    python3 \
    python3-dev \
    php7 \
    php7-curl \
    php7-fileinfo \
    php7-json \
  && pip3 install --no-cache-dir --upgrade pip \
  && rm -rf /var/cache/* \
  && rm -rf /root/.cache/*

RUN cd /usr/bin \
  && ln -sf python3 python \
  && ln -sf pip3 pip

RUN pip install nltk==3.4.5
RUN pip install mkdocs pyaml pymdown-extensions mkdocs-redirects markdown-callouts

COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY do-we-build-and-if-so-what.php /usr/bin/do-we-build-and-if-so-what.php
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
