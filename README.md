[![nginx 1.29.8](https://img.shields.io/badge/nginx-1.29.8-brightgreen.svg?&logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES) 
[![php 8.5](https://img.shields.io/badge/php--fpm-8.5-blue.svg?&logo=php&logoColor=white&style=for-the-badge)](https://www.php.net/ChangeLog-8.php#8.5)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](https://github.com/LordMrcS/nginx-php-fpm/blob/master/LICENSE)

## Introduction
This is a Dockerfile to build an alpine based container image running nginx and php-fpm 8.5.x & Composer.

### Versioning
| Docker Tag | GitHub Release | Nginx Version | PHP Version | Base Image | Composer 
|------------|----------------|---------------|-------------|------------|----------|
| latest     | master Branch  | 1.29.8        | 8.5         | Alpine edge| 2.9.5    |
| alpine     | migrate-to-alpine Branch | 1.29.8 | 8.5   | Alpine edge| 2.9.5    |


## Building from source
To build from source you need to clone the git repo and run docker build:
```
$ git clone https://github.com/LordMrcS/nginx-php-fpm.git
$ cd nginx-php-fpm
```

followed by
```
$ docker build -t nginx-php-fpm:alpine . # PHP 8.5 (Alpine edge)
```


## Pulling from Docker Hub
```
$ docker pull mrcs2000/nginx-php-fpm-ldap
```

## Pulling from Github Container Registry
```
$ docker pull ghcr.io/lordmrcs/nginx-php-fpm:alpine
```

## Running
To run via CLI the container from Github:
```
$ sudo docker run -d ghcr.io/lordmrcs/nginx-php-fpm:alpine
```

Default web root:
```
/usr/share/nginx/html
```
## Running via docker-compose stack file
This example mounts the default nginx HTML path to ./www, overrides nginx and PHP default confs and exposes port 80.
```
version: '3'
services:
  web:
    image: ghcr.io/lordmrcs/nginx-php-fpm:alpine
    volumes:
      - ./www/:/usr/share/nginx/html/
      - ./default.conf:/etc/nginx/conf.d/default.conf
      - ./php.ini:/etc/php/8.5/php.ini
    ports:
      - 80:80
```

---
Forked from [wyveo/nginx-php-fpm](https://github.com/wyveo/nginx-php-fpm)