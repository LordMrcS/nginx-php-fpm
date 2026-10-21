[![nginx 1.31.8](https://img.shields.io/badge/nginx-1.31.8-brightgreen.svg?logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES)
[![PHP 8.5.12](https://img.shields.io/badge/php--fpm-8.5.12-blue.svg?logo=php&logoColor=white&style=for-the-badge)](https://www.php.net/ChangeLog-8.php)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)

## Introduction

This branch builds Nginx 1.31.8, PHP-FPM 8.5.12, Composer 2.10.3 and
PIE 1.5.2 on Alpine 3.24.

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

PHP comes from the official `php:8.5.12-fpm-alpine3.24` image.
Nginx is built from upstream mainline source with SHA-256 verification, and
Composer uses its upstream installer with SHA-384 verification. Distribution
repositories supply supporting libraries and tools only. Versions are explicit;
update the build and this README together when adopting upstream releases.

## Build and validate

```sh
git clone --branch master https://github.com/LordMrcS/nginx-php-fpm.git
cd nginx-php-fpm
docker build --pull --no-cache -t nginx-php-fpm:latest .
sh tests/smoke.sh nginx-php-fpm:latest
```

The smoke test checks exact versions, PHP extensions, service configuration and
PHP rendering over HTTP, PIE availability and removal of the legacy installer
commands.

## PHP extension installer

On `master`, [PIE](https://php.github.io/pie/) 1.5.2 replaces the inherited
PECL/PEAR commands. Its upstream PHAR is pinned and verified against SHA-256.
PIE installs these native extensions on `master`:

| PIE package | Extension | Version |
|---|---|---|
| `phpredis/phpredis` | `redis` (phpredis) | 6.3.0 |
| `php-memcached/php-memcached` | `memcached` | 3.4.0 |
| `imagick/imagick` | `imagick` | 3.8.1 |

Redis uses the native phpredis extension. Bundled extensions such as GD
and LDAP continue to use `docker-php-ext-install`; external extensions use PIE
package names and explicit versions.

Build tools are installed while PIE compiles the extensions, then removed.
PIE enables each extension automatically. Supporting ImageMagick and Memcached
libraries remain in the runtime image. The smoke test exercises the native
Redis and Memcached classes and an Imagick PNG round trip through PHP-FPM.

This migration applies to `master`; the other branches retain their installers.

## Publish branch images to Docker Hub

In GitHub Actions, open **Publish non-master branches to Docker Hub**, select
`master` as the workflow branch, and click **Run workflow**. One manual run
builds and tests all five maintained non-master branches, then pushes the tested
images to `${DOCKER_USERNAME}/nginx-php-fpm-ldap` using these tags:

| Source branch | Docker Hub tag |
|---|---|
| `php82` | `php82` |
| `php83` | `php83` |
| `php84` | `php84` |
| `php85` | `php85` |
| `alpine-8.5` | `alpine` |

The workflow uses the existing `DOCKER_USERNAME` and `DOCKER_PASSWORD` repository
secrets, pulls fresh upstream layers and builds without cache. It runs only when
manually triggered. The existing `master` publishing workflow remains separate.

## Run

```sh
docker pull ghcr.io/lordmrcs/nginx-php-fpm:latest
docker run -d -p 8080:80 ghcr.io/lordmrcs/nginx-php-fpm:latest
```

The default web root is `/usr/share/nginx/html`. Existing configuration paths
are retained: `/etc/php85/php.ini` links to `/usr/local/etc/php/php.ini`.
The upstream `php` and `php-fpm` commands and versioned compatibility commands
are available.

```yaml
services:
  web:
    image: ghcr.io/lordmrcs/nginx-php-fpm:latest
    volumes:
      - ./www/:/usr/share/nginx/html/
      - ./default.conf:/etc/nginx/http.d/default.conf
      - ./php.ini:/etc/php85/php.ini
    ports:
      - "8080:80"
```

The Docker Hub image is also available as `mrcs2000/nginx-php-fpm-ldap:latest`.

---
Forked from [wyveo/nginx-php-fpm](https://github.com/wyveo/nginx-php-fpm).
