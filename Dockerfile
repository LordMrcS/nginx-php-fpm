FROM php:8.2.35-fpm-bookworm

ENV NGINX_VERSION=1.31.8
ENV PHP_V=8.2
ENV php_conf=/etc/php/${PHP_V}/fpm/php.ini
ENV fpm_conf=/etc/php/${PHP_V}/fpm/pool.d/www.conf
ENV COMPOSER_VERSION=2.10.3
ENV DOCUMENT_ROOT=/usr/share/nginx/html
ENV REDIS_VERSION=6.3.0
ENV MEMCACHED_VERSION=3.4.0
ENV IMAGICK_VERSION=3.8.1

# PHP is supplied by the official upstream image, never by distribution packages.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget bash tini nano zip unzip git supervisor python3 \
    $PHPIZE_DEPS libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
    libicu-dev libldap2-dev libpq-dev libzip-dev libsnmp-dev libxslt1-dev \
    libmemcached-dev libsasl2-dev libmagickwand-dev libpcre2-dev libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j2 bcmath gd intl ldap mysqli pdo_mysql pdo_pgsql pgsql snmp soap xsl zip; \
    pecl install redis-${REDIS_VERSION} memcached-${MEMCACHED_VERSION} imagick-${IMAGICK_VERSION}; \
    docker-php-ext-enable redis memcached imagick; \
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
    rm -rf /tmp/pear

# Preserve Debian-style configuration mounts and versioned executable names.
RUN set -eux; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    mkdir -p "/etc/php/${PHP_V}" /run/php; \
    ln -s "$PHP_INI_DIR" "/etc/php/${PHP_V}/fpm"; \
    ln -s "$PHP_INI_DIR" "/etc/php/${PHP_V}/cli"; \
    ln -s /usr/local/etc/php-fpm.d "$PHP_INI_DIR/pool.d"; \
    ln -s /usr/local/etc/php-fpm.conf "$PHP_INI_DIR/php-fpm.conf"; \
    ln -s /usr/local/bin/php "/usr/bin/php${PHP_V}"; \
    ln -s /usr/local/sbin/php-fpm "/usr/sbin/php-fpm${PHP_V}"; \
    printf '[www]\nlisten = /run/php/php%s-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0660\n' "$PHP_V" > /usr/local/etc/php-fpm.d/zzzz-listen.conf

RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
    sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} && \
    sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf}

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /usr/local/etc/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} && \
    sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} && \
    sed -i -e "s/^user = .*/user = www-data/" ${fpm_conf} && \
    sed -i -e "s/^group = .*/group = www-data/" ${fpm_conf}

RUN curl -fsSL -o /tmp/composer-setup.php https://getcomposer.org/installer && \
    curl -fsSL -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
    rm -f /tmp/composer-setup.php /tmp/composer-setup.sig

COPY ./supervisord.conf /etc/supervisord.conf
COPY ./supervisor_stdout.py /usr/bin/supervisor_stdout.py
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./default.conf /etc/nginx/conf.d/default.conf
COPY html /usr/share/nginx/html
COPY ./start.sh /start.sh
RUN chmod +x /usr/bin/supervisor_stdout.py /start.sh

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost/ || exit 1
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
