[![nginx 1.31.8](https://img.shields.io/badge/nginx-1.31.8-brightgreen.svg?logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES)
[![PHP 8.4.27](https://img.shields.io/badge/php--fpm-8.4.27-blue.svg?logo=php&logoColor=white&style=for-the-badge)](https://www.php.net/ChangeLog-8.php)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)

## Introduction

This branch builds Nginx 1.31.8, PHP-FPM 8.4.27 and Composer 2.10.3 on
Debian 12 (bookworm).

## Versions

| Docker tag | Git branch | Nginx | PHP | Base | Composer |
|---|---|---|---|---|---|
| latest | master | 1.31.8 | 8.5.12 | Alpine 3.24 | 2.10.3 |
| alpine | alpine-8.5 | 1.31.8 | 8.5.12 | Alpine 3.24 | 2.10.3 |
| php85 | php85 | 1.31.8 | 8.5.12 | Debian 13 (trixie) | 2.10.3 |
| php84 | php84 | 1.31.8 | 8.4.27 | Debian 12 (bookworm) | 2.10.3 |
| php83 | php83 | 1.31.8 | 8.3.36 | Debian 12 (bookworm) | 2.10.3 |
| php82 | php82 | 1.31.8 | 8.2.35 | Debian 12 (bookworm) | 2.10.3 |

PHP 8.1 is retired. Each maintained branch stays on its PHP minor release line;
Nginx and Composer use the latest upstream releases across all branches.

PHP comes from the official `php:8.4.27-fpm-bookworm` image.
Nginx is built from upstream mainline source with SHA-256 verification, and
Composer uses its upstream installer with SHA-384 verification. Distribution
repositories supply supporting libraries and tools only. Versions are explicit;
update the build and this README together when adopting upstream releases.

## Build and validate

```sh
git clone --branch php84 https://github.com/LordMrcS/nginx-php-fpm.git
cd nginx-php-fpm
docker build --pull --no-cache -t nginx-php-fpm:php84 .
sh tests/smoke.sh nginx-php-fpm:php84
```

The smoke test checks exact versions, PHP extensions, service configuration and
PHP rendering over HTTP.

## Run

```sh
docker pull ghcr.io/lordmrcs/nginx-php-fpm:php84
docker run -d -p 8080:80 ghcr.io/lordmrcs/nginx-php-fpm:php84
```

The default web root is `/usr/share/nginx/html`. Existing configuration paths
are retained: `/etc/php/8.4/fpm/php.ini` links to `/usr/local/etc/php/php.ini`.
The upstream `php` and `php-fpm` commands and versioned compatibility commands
are available.

```yaml
services:
  web:
    image: ghcr.io/lordmrcs/nginx-php-fpm:php84
    volumes:
      - ./www/:/usr/share/nginx/html/
      - ./default.conf:/etc/nginx/conf.d/default.conf
      - ./php.ini:/etc/php/8.4/fpm/php.ini
    ports:
      - "8080:80"
```

The Docker Hub image is also available as `mrcs2000/nginx-php-fpm-ldap:latest`.

---
Forked from [wyveo/nginx-php-fpm](https://github.com/wyveo/nginx-php-fpm).
