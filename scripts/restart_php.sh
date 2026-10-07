#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd -- "$script_dir/.." && pwd -P)"
cd -- "$project_dir"

podman-compose --file compose.yaml exec php php-fpm -t
podman-compose --file compose.yaml restart php
./scripts/restart_nginx.sh

echo "PHP-FPM configuration is valid; PHP and its Nginx dependent were restarted."
