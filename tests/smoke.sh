#!/bin/sh
set -eu
image=${1:-nginx-php-fpm:php84-check}
docker run --rm --entrypoint /bin/bash "$image" -c '
set -euo pipefail
nginx -v 2>&1 | grep -F "nginx/1.31.8"
php8.4 -r '\''if (PHP_VERSION !== "8.4.27") { fwrite(STDERR, "Expected PHP 8.4.27, got " . PHP_VERSION . PHP_EOL); exit(1); } foreach (["curl", "gd", "mysqli", "zip", "pgsql", "intl", "xml", "ldap", "Phar", "mbstring", "bcmath", "pdo_mysql", "pdo_pgsql", "snmp", "soap", "xsl", "redis", "memcached", "imagick"] as $ext) { if (!extension_loaded($ext)) { fwrite(STDERR, "Missing extension: $ext\n"); exit(1); } }'\''
php8.4 /usr/local/bin/composer --version | grep -F "2.10.3"
nginx -t
php-fpm8.4 -t
/start.sh > /tmp/smoke.log 2>&1 & app_pid=$!
trap "kill $app_pid 2>/dev/null || true" EXIT
for attempt in $(seq 1 20); do
    if wget -q -O /tmp/response http://127.0.0.1/; then break; fi
    sleep 1
done
grep -q "8.4.27" /tmp/response
grep -q "v1.31.8" /tmp/response
if grep -q "<?php" /tmp/response; then exit 1; fi
wget -q --spider http://localhost/
echo "Upstream versions, extensions, configuration and HTTP/PHP-FPM smoke test passed"
'
