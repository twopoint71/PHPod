# PHP Podman starter

A small Podman-first development stack with Nginx, PHP-FPM, PostgreSQL, and
Redis. The application is available only on the local machine by default.

## Requirements

- Podman with rootless containers configured
- `podman-compose`
- Bash, OpenSSL, and curl

The Compose file uses Podman external secrets and SELinux `:z` bind-mount
labels. Docker compatibility is not a goal of this template without adapting
those features.

## First run

Create the local configuration, initialize the database secret, build the
custom images, and start the stack:

```bash
cp .env.example .env
./scripts/initialize.sh
./scripts/start.sh
./scripts/smoke.sh
```

Open <http://127.0.0.1:8080>. Change `APP_PORT` in `.env` if that port is
already occupied.

`initialize.sh` is idempotent. It preserves an existing PostgreSQL password
and supports targeted or cache-free builds:

```bash
./scripts/initialize.sh php
./scripts/initialize.sh nginx
./scripts/initialize.sh all --no-cache
```

## Project layout

```text
public/          Nginx document root; only public files belong here
src/             application source that must not be served directly
Containerfiles/  Nginx and PHP image definitions and configuration
scripts/         lifecycle and smoke-test commands
```

PHP sees the repository at `/var/www/html`. Nginx sees only `public/`, mounted
read-only. Install Composer dependencies into `vendor/`; that directory is
ignored by Git and remains outside the public document root.

Application configuration is supplied through environment variables. The
PostgreSQL password is mounted into PHP and PostgreSQL at
`/run/secrets/postgres_password`; it is not stored in an environment variable.

## Lifecycle

Start or stop the stack:

```bash
./scripts/start.sh
./scripts/stop.sh
```

Nginx and PHP-FPM configuration files are mounted read-only from
`Containerfiles/`, so configuration-only changes do not require rebuilding an
image. Validate the changed configuration and restart just the affected
service with:

```bash
./scripts/restart_nginx.sh
./scripts/restart_php.sh
```

The scripts stop before restarting if the respective configuration test fails.
The PHP script restarts Nginx afterward so Nginx resolves PHP's current Podman
network address.

Stopping preserves the `postgres-data` and `redis-data` named volumes. To
intentionally erase all database and Redis data and start fresh:

```bash
podman-compose --file compose.yaml down --volumes
```

That reset is destructive. It is required if you change `POSTGRES_USER`,
`POSTGRES_DB`, or the PostgreSQL password after the database volume has already
been initialized.

To replace the external password secret as part of an intentional database
reset:

```bash
podman secret rm postgres_password
rm .secrets/postgres_password
./scripts/initialize.sh
```

## Health checks

Compose checks PostgreSQL, Redis, and PHP-FPM before starting dependent
services. `public/health.php` checks the complete PHP-to-service path and
returns HTTP 503 without exposing exception details if a dependency is down.

Run the host-side smoke test with:

```bash
./scripts/smoke.sh
```

If testing a non-default address, set `APP_URL` explicitly:

```bash
APP_URL=http://127.0.0.1:9080 ./scripts/smoke.sh
```

## Updating versions

Image and extension versions are deliberately pinned in `compose.yaml` and the
files under `Containerfiles/`. After changing a version, rebuild and recreate
the services:

```bash
./scripts/initialize.sh all --no-cache
./scripts/stop.sh
./scripts/start.sh
./scripts/smoke.sh
```

Review PostgreSQL major-version migration instructions before changing its
major version; do not point a newer major release directly at an older data
directory.
