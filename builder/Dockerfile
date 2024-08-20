FROM python:3-alpine

RUN pip install --upgrade pip

# PHP and bash are required for the theme installer

RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache \
    php \
    bash

# Install markdown with required libs and plugins
RUN pip install \
    pyyaml \
    markdown \
    mkdocs \
    pymdown-extensions \
    markdown-callouts \
    mkdocs-redirects
