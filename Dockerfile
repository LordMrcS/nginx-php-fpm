FROM alpine:edge

ENV NGINX_VERSION=1.29.8
ENV PHP_V=85
ENV PHP_INI=/etc/php${PHP_V}/php.ini
ENV PHP_FPM=/etc/php${PHP_V}/php-fpm.d/www.conf
ENV PHP_FPM_CONF=/etc/php${PHP_V}/php-fpm.conf
ENV COMPOSER_VERSION=2.9.5

RUN apk update && apk add --no-cache --verbose curl gcc make autoconf libc-dev zlib-dev pkgconfig wget ca-certificates bash

RUN addgroup -g 82 -S www-data && \
    adduser -u 82 -D -S -G www-data www-data

RUN apk add --no-cache --verbose nginx php${PHP_V} php${PHP_V}-fpm php${PHP_V}-cli php${PHP_V}-curl php${PHP_V}-gd php${PHP_V}-mysqli php${PHP_V}-zip php${PHP_V}-pgsql php${PHP_V}-intl php${PHP_V}-xml php${PHP_V}-ldap php${PHP_V}-phar php${PHP_V}-mbstring

RUN apk add --no-cache --verbose perl nano zip unzip git

RUN apk add --no-cache --verbose libmemcached-dev imagemagick-dev supervisor python3 py3-pip || echo "Optional packages failed, continuing..."

RUN mkdir -p /run/php && rm -rf /etc/nginx/sites-enabled/default

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
    sed -i -e "s/^;clear_env = no$/clear_env = no/" ${PHP_FPM}

RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer && \
    curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
    php${PHP_V} -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php${PHP_V} /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} && \
    rm -rf /tmp/composer-setup.php

COPY ./supervisord.conf /etc/supervisord.conf
COPY ./supervisor_stdout.py /usr/bin/supervisor_stdout.py
RUN chmod o+x /usr/bin/supervisor_stdout.py

COPY ./default.conf /etc/nginx/conf.d/default.conf

COPY html /usr/share/nginx/html

COPY ./start.sh /start.sh

EXPOSE 80

CMD ["/start.sh"]