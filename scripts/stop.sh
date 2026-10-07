#!/usr/bin/env bash

set -Eeuo pipefail

# set current dir to project root
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd -- "$script_dir/.." && pwd -P)"
cd -- "$project_dir"

podman-compose --file compose.yaml down
