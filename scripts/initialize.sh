#!/usr/bin/env bash

set -Eeo pipefail

# 1. set current dir to project root
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd -- "$script_dir/.." && pwd -P)"
cd -- "$project_dir"

# 2. Validate the requested Compose build before changing local state.
TARGET_SERVICE="${1:-all}"
BUILD_ARGS=(--file compose.yaml build)
BUILD_SERVICES=()

case "$TARGET_SERVICE" in
    all)
        ;;
    nginx)
        BUILD_SERVICES+=(web)
        ;;
    php)
        BUILD_SERVICES+=(php)
        ;;
    *)
        echo "Error: expected service 'nginx', 'php', or 'all'; got '${TARGET_SERVICE}'." >&2
        exit 2
        ;;
esac

if [[ "${2:-}" == "--no-cache" ]]; then
    BUILD_ARGS+=(--no-cache)
elif [[ -n "${2:-}" ]]; then
    echo "Error: unsupported option '${2}'." >&2
    exit 2
fi

# 3. Create the external Podman secret before starting the stack.
postgres_password_label="postgres_password"
secret_dir=".secrets"
secret_file="${secret_dir}/${postgres_password_label}"

install -d -m 700 "$secret_dir"

if [[ -f "$secret_file" ]]; then
    chmod 600 "$secret_file"
fi

if podman secret exists "$postgres_password_label"; then
    echo "PostgreSQL password secret already exists."
else
    if [[ ! -s "$secret_file" ]]; then
        echo "Generating PostgreSQL password."
        umask 077
        ./scripts/rand_pass.sh > "$secret_file"
    fi

    podman secret create "$postgres_password_label" "$secret_file"
    echo "PostgreSQL password secret created."
fi

# 4. Build the requested custom images through Compose.
BUILD_ARGS+=("${BUILD_SERVICES[@]}")
podman-compose "${BUILD_ARGS[@]}"

echo "✅ All requested images built successfully."
