[![nginx 1.23.17](https://img.shields.io/badge/nginx-1.23.17-brightgreen.svg?&logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES)
[![php 8.1](https://img.shields.io/badge/php--fpm-8.1-blue.svg?&logo=php&logoColor=white&style=for-the-badge)](https://www.php.net/ChangeLog-8.php#8.1)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](https://github.com/LordMrcS/nginx-php-fpm/blob/master/LICENSE)

## Introduction
This is a Dockerfile to build a Debian based container image running nginx and php-fpm 8.1.x & Composer.

### Versioning
| Docker Tag | GitHub Branch | Nginx Version | PHP Version | Debian Version | Composer
|------------|--------------|---------------|-------------|--------------|----------|
| latest     | master       | 1.29.8        | 8.5        | Alpine edge  | 2.9.5     |
|php85-bookworm| php85        | 1.29.8        | 8.5        | Debian 13   | 2.9.5     |
| php84      | php84        | 1.29.8        | 8.4        | Debian 12   | 2.9.5     |
| php83      | php83        | 1.28.1        | 8.3        | Debian 12   | 2.9.5     |
| php82      | php82        | 1.26.4        | 8.2        | Debian 12   | 2.9.5     |
| php81      | php81        | 1.23.17       | 8.1        | Debian 11   | 2.9.5     |


## Building from source
To build from source you need to clone the git repo and run docker build:
```
$ git clone https://github.com/LordMrcS/nginx-php-fpm.git
$ cd nginx-php-fpm
```

followed by
```
$ docker build -t nginx-php-fpm:php81 . # PHP 8.1.x
```


## Pulling from Docker Hub
```
$ docker pull mrcs2000/nginx-php-fpm-ldap
```

## Pulling from Github Container Registry
```
$ docker pull ghcr.io/lordmrcs/nginx-php-fpm:php81
```

## Running
To run the container:
```
$ sudo docker run -d ghcr.io/lordmrcs/nginx-php-fpm:php81
```

Default web root:
```
/usr/share/nginx/html
```

---
Forked from [wyveo/nginx-php-fpm](https://github.com/wyveo/nginx-php-fpm)