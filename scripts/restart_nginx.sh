#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd -- "$script_dir/.." && pwd -P)"
cd -- "$project_dir"

podman-compose --file compose.yaml exec web nginx -t
podman-compose --file compose.yaml restart web

echo "Nginx configuration is valid and the web service was restarted."

