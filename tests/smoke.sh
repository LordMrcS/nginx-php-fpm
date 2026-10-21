#!/bin/sh
set -eu
image=${1:-nginx-php-fpm:upstream-check}
docker run --rm --entrypoint /bin/bash "$image" -c '
set -euo pipefail
nginx -v 2>&1 | grep -F "nginx/1.31.8"
php85 -r '\''if (PHP_VERSION !== "8.5.12") { fwrite(STDERR, "Expected PHP 8.5.12, got " . PHP_VERSION . PHP_EOL); exit(1); } foreach (["curl", "gd", "mysqli", "zip", "pgsql", "intl", "xml", "ldap", "Phar", "mbstring"] as $ext) { if (!extension_loaded($ext)) { fwrite(STDERR, "Missing extension: $ext\n"); exit(1); } }'\''
php85 /usr/local/bin/composer --version | grep -F "2.10.3"
nginx -t
php-fpm85 -t
/start.sh > /tmp/smoke.log 2>&1 & app_pid=$!
trap "kill $app_pid 2>/dev/null || true" EXIT
for attempt in $(seq 1 20); do
    if wget -q -O /tmp/response http://127.0.0.1/; then break; fi
    sleep 1
done
grep -q "8.5.12" /tmp/response
grep -q "v1.31.8" /tmp/response
if grep -q "<?php" /tmp/response; then exit 1; fi
wget -q --spider http://localhost/
echo "Upstream versions, extensions, configuration and HTTP/PHP-FPM smoke test passed"
'
