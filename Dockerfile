FROM php:8.5.12-fpm-alpine3.24

ENV NGINX_VERSION=1.31.8
ENV PHP_V=85
ENV PHP_INI=/etc/php${PHP_V}/php.ini
ENV PHP_FPM=/etc/php${PHP_V}/php-fpm.d/www.conf
ENV PHP_FPM_CONF=/etc/php${PHP_V}/php-fpm.conf
ENV COMPOSER_VERSION=2.10.3
ENV PIE_VERSION=1.5.2
ENV DOCUMENT_ROOT=/usr/share/nginx/html

# PHP comes from the official upstream image; never install Alpine php packages.
RUN apk add --no-cache curl wget ca-certificates bash tini perl nano zip unzip git \
    libmemcached-dev imagemagick-dev supervisor python3 py3-pip \
    freetype libjpeg-turbo libpng libwebp icu-libs libldap libpq libzip pcre2 openssl zlib

RUN set -eux; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
        freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev icu-dev \
        openldap-dev postgresql-dev libzip-dev pcre2-dev openssl-dev zlib-dev linux-headers; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" gd intl ldap mysqli pgsql zip; \
    curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o /tmp/nginx.tar.gz; \
    echo "0652b760b3b772d2ec17b47c2fc15d9a95e6fe35cd5b877eadc1a62d9bc75af1  /tmp/nginx.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/nginx.tar.gz -C /tmp; \
    cd "/tmp/nginx-${NGINX_VERSION}"; \
    ./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf --pid-path=/run/nginx.pid \
        --error-log-path=/dev/stderr --http-log-path=/dev/stdout \
        --user=www-data --group=www-data --with-http_ssl_module \
        --with-http_v2_module --with-http_gzip_static_module --with-threads; \
    make -j"$(nproc)"; \
    make install; \
    cd /; \
    rm -rf "/tmp/nginx-${NGINX_VERSION}" /tmp/nginx.tar.gz; \
    apk del .build-deps

# Keep the existing php85 commands and /etc/php85 mount paths compatible.
RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    ln -s /usr/local/etc/php /etc/php${PHP_V} && \
    ln -s /usr/local/etc/php-fpm.d "$PHP_INI_DIR/php-fpm.d" && \
    ln -s /usr/local/etc/php-fpm.conf "$PHP_INI_DIR/php-fpm.conf" && \
    ln -s /usr/local/bin/php /usr/bin/php${PHP_V} && \
    ln -s /usr/local/sbin/php-fpm /usr/sbin/php-fpm${PHP_V}

RUN mkdir -p /run/php

RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${PHP_INI} && \
    sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${PHP_INI} && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${PHP_INI} && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${PHP_INI} && \
    sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${PHP_INI}

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" ${PHP_FPM_CONF} && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${PHP_FPM} && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${PHP_FPM} && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${PHP_FPM} && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${PHP_FPM} && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${PHP_FPM} && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${PHP_FPM} && \
    sed -i -e "s/^;clear_env = no$/clear_env = no/" ${PHP_FPM} && \
    sed -i -e "s/^user = .*/user = www-data/" ${PHP_FPM} && \
    sed -i -e "s/^group = .*/group = www-data/" ${PHP_FPM}

RUN curl -fsSL -o /tmp/composer-setup.php https://getcomposer.org/installer && \
    curl -fsSL -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
    php${PHP_V} -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php${PHP_V} /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
    rm -f /tmp/composer-setup.php /tmp/composer-setup.sig

ENV REDIS_VERSION=6.3.0
ENV MEMCACHED_VERSION=3.4.0
ENV IMAGICK_VERSION=3.8.1

# Use upstream PIE for external extensions; bundled extensions use docker-php-ext-install.
RUN curl -fsSL "https://github.com/php/pie/releases/download/${PIE_VERSION}/pie.phar" -o /usr/local/bin/pie && \
    echo "fe70c59738cf56ec00a818cf9cb9593da171aac86f5f1f859995b8839dfd2cc7  /usr/local/bin/pie" | sha256sum -c - && \
    chmod +x /usr/local/bin/pie && \
    rm -f /usr/local/bin/pecl /usr/local/bin/pear /usr/local/bin/peardev && \
    pie --version && \
    apk add --no-cache --virtual .pie-build-deps $PHPIZE_DEPS automake libtool zlib-dev && \
    pie install --no-interaction --make-parallel-jobs=2 "phpredis/phpredis:${REDIS_VERSION}" && \
    pie install --no-interaction --make-parallel-jobs=2 "php-memcached/php-memcached:${MEMCACHED_VERSION}" && \
    pie install --no-interaction --make-parallel-jobs=2 "imagick/imagick:${IMAGICK_VERSION}" && \
    apk del .pie-build-deps

COPY ./supervisord.conf /etc/supervisord.conf
COPY ./supervisor_stdout.py /usr/bin/supervisor_stdout.py
RUN chmod +x /usr/bin/supervisor_stdout.py

RUN rm -rf /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default.conf /etc/nginx/http.d/default.conf

COPY html /usr/share/nginx/html

COPY ./start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost/ || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
