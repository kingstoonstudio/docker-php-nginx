ARG ALPINE_VERSION=3.19
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Gábor Móró <moro.gabor@kingstoonstudio.com>"
LABEL Description="Lightweight container with Nginx 1.24 & PHP 8.3 based on Alpine Linux. (Forked from TrafeX/docker-php-nginx)"
# Setup document root
WORKDIR /WWW
RUN mkdir -p /var/www/html

ENV PHP_INI_DIR /etc/php83

# Setup app user
RUN addgroup -g 65000 app
RUN adduser -s /sbin/nologin -G app -D -H -u 65000 app
RUN adduser app app

# Install language pack
RUN apk add --no-cache --update tzdata
ENV TZ=Europe/Budapest
RUN cp /usr/share/zoneinfo/Europe/Budapest /etc/localtime

ENV LANG hu_HU.UTF-8
ENV LANGUAGE hu_HU.UTF-8
ENV LC_ALL hu_HU.UTF-8

RUN apk --no-cache add libintl icu icu-dev icu-data-full musl-locales musl-locales-lang

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php83 \
  php83-ctype \
  php83-curl \
  php83-dom \
  php83-enchant \
  php83-fileinfo \
  php83-fpm \
  php83-gd \
  php83-intl \
  php83-mbstring \
  php83-mysqli \
  php83-opcache \
  php83-openssl \
  php83-pdo \
  php83-pdo_mysql \
  php83-pdo_odbc \
  php83-pdo_pgsql \
  php83-pdo_sqlite \
  php83-pgsql \
  php83-phar \
  php83-pspell \
  php83-session \
  php83-simplexml \
  php83-soap \
  php83-sqlite3 \
  php83-tokenizer \
  php83-xml \
  php83-xmlreader \
  php83-xmlwriter \
  php83-zip \
  php83-pecl-ssh2 \
  php83-pecl-yaml \
  php83-pecl-redis \
  php83-pecl-mailparse \
  php83-pecl-memcache \
  php83-pecl-memcached \
  supervisor

# Volumes
VOLUME /etc/nginx
VOLUME ${PHP_INI_DIR}

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R app.app /var/www/html /run /var/lib/nginx /var/log/nginx /WWW

# Create symlink for php
RUN ln -s /usr/bin/php83 /usr/bin/php

# Switch to use a non-root user from here on
USER app

# Add application
COPY --chown=app src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
