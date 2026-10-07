#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd -- "$script_dir/.." && pwd -P)"
cd -- "$project_dir"

if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
fi

app_port="${APP_PORT:-8080}"
base_url="${APP_URL:-http://127.0.0.1:${app_port}}"
health_url="${base_url%/}/health.php"

response="$(curl --fail --silent --show-error --max-time 10 "$health_url")"
grep -q '"status": "ok"' <<<"$response"

printf 'Smoke test passed: %s\n' "$health_url"
