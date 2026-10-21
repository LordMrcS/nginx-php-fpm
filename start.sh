#!/bin/bash
set -euo pipefail

procs=$(nproc)
sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf

find /usr/share/nginx/html ! -user www-data -exec chown www-data:www-data {} \; || true

exec supervisord -n -c /etc/supervisord.conf