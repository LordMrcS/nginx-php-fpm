FROM alpine:edge

ENV NGINX_VERSION 1.29.8
ENV PHP_V 8.5
ENV php_conf /etc/php${PHP_V}/php.ini
ENV fpm_conf /etc/php${PHP_V}/php-fpm.d/www.conf
ENV COMPOSER_VERSION 2.9.5

RUN set -x \
    && apk add --no-cache \
            curl \
            gcc \
            make \
            autoconf \
            libc-dev \
            zlib-dev \
            pkgconfig \
            wget \
            ca-certificates \
            bash \
    && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -G www-data www-data \
    && apk add --no-cache \
            nginx \
            php${PHP_V}-fpm \
            php${PHP_V}-cli \
            php${PHP_V}-bcmath \
            php${PHP_V}-common \
            php${PHP_V}-opcache \
            php${PHP_V}-mbstring \
            php${PHP_V}-curl \
            php${PHP_V}-gd \
            php${PHP_V}-mysqli \
            php${PHP_V}-zip \
            php${PHP_V}-pgsql \
            php${PHP_V}-intl \
            php${PHP_V}-xml \
            php${PHP_V}-ldap \
            php${PHP_V}-pear \
            perl \
            nano \
            zip \
            unzip \
            git \
            libmemcached-dev \
            imagemagick-dev \
            supervisor \
            python3 \
            py3-pip \
    && pecl -d php_suffix=${PHP_V} install -o -f redis \
    && mkdir -p /run/php \
    && rm -rf /etc/nginx/sites-enabled/default \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php${PHP_V}/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php${PHP_V}/conf.d/redis.ini \
    && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
    && rm -rf /tmp/composer-setup.php

COPY ./supervisord.conf /etc/supervisord.conf
COPY ./supervisor_stdout.py /usr/bin/supervisor_stdout.py
RUN chmod o+x /usr/bin/supervisor_stdout.py

COPY ./default.conf /etc/nginx/conf.d/default.conf

COPY html /usr/share/nginx/html

COPY ./start.sh /start.sh

EXPOSE 80

USER www-data

CMD ["/start.sh"]