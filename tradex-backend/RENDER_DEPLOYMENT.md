# Render deployment preparation

This backend is prepared as a single Render Docker web service. The existing
Laravel routes remain unchanged, so the same service serves both the REST API
under `/api/v1/*` and the server-rendered Admin Dashboard under `/admin/*`.

## Render service

Use the repository-root `render.yaml` Blueprint, or create a Render Web Service
with:

- Runtime: **Docker**
- Root directory: `tradex-backend`
- Dockerfile: `Dockerfile`
- Health check path: `/api/v1/health`

The Docker build installs production Composer dependencies, installs the
frontend dependencies, and runs the Vite production build. The container start
command is:

```sh
php -S 0.0.0.0:${PORT:-8000} -t public docker/router.php
```

The Docker image uses `docker/router.php` as the PHP built-in server router so
existing files under `public/` (including Vite assets) are served directly.

The entrypoint creates writable Laravel directories, runs `storage:link`, applies
pending schema-only migrations with `php artisan migrate --force`, and runs
`php artisan optimize` before starting that one Laravel web server with `public`
as its document root. It does not run seeders or create users.

The Blueprint mounts the `tradex-storage` Persistent Disk at
`/var/www/html/storage`. This keeps files on Laravel's `public` disk under
`storage/app/public` across deploys and restarts while leaving
`storage/app/private` outside the public web root.

## Required environment variable names

Set these in Render. Never commit their values:

```text
APP_ENV
APP_DEBUG
APP_KEY
APP_URL
DB_CONNECTION
DB_HOST
DB_PORT
DB_DATABASE
DB_USERNAME
DB_PASSWORD
FILESYSTEM_DISK
SESSION_DRIVER
CACHE_STORE
QUEUE_CONNECTION
LOG_CHANNEL
LOG_LEVEL
CORS_ALLOWED_ORIGINS
SANCTUM_EXPIRATION_MINUTES
```

For the recommended PostgreSQL deployment, use `DB_CONNECTION=pgsql`,
`DB_PORT=5432`, and the connection values supplied by the selected PostgreSQL
service. Generate one Laravel application key and keep it stable across
releases. Set `APP_URL` to the final HTTPS Render URL.

Optional integrations keep their existing variable names and are only needed
when their features are enabled:

```text
GEMINI_API_KEY
MAIL_MAILER
MAIL_HOST
MAIL_PORT
MAIL_USERNAME
MAIL_PASSWORD
MAIL_FROM_ADDRESS
MAIL_FROM_NAME
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
```

For a browser client hosted on another origin, set
`CORS_ALLOWED_ORIGINS` to a comma-separated list of trusted HTTPS origins. The
Flutter mobile client does not require browser CORS. Same-origin Admin
Dashboard requests do not require an additional CORS origin.

## Database status

The checked-in `database/database.sqlite` is the existing local/development
database and was not migrated, copied into the image, or modified for this
preparation. It is not a suitable durable Render production database.

PostgreSQL is recommended before production use. Laravel already has a
PostgreSQL connection definition, and the Docker image now includes the
`pdo_pgsql` extension. Before the first production request:

1. Provision/select the PostgreSQL database.
2. Set the `DB_*` variables in Render.
3. Review/export/import the existing SQLite data separately if production must
   retain it; do not point PostgreSQL at the SQLite file.
4. The container entrypoint runs `php artisan migrate --force` against the
   configured PostgreSQL database before serving requests.
5. Seed only through an explicit, reviewed data migration or import. The
   deployment configuration does not run seeders.

The sessions migration is schema-only and is applied by the container entrypoint.
It supports the configured database-backed Admin Dashboard sessions.

SQLite on Render is only a temporary single-instance option with a paid
Persistent Disk mounted over the database/storage locations and a backup plan.
It is not compatible with stateless scaling or a disposable filesystem.

## Uploaded files

Avatars, store/category/product images, and private subscription proofs are
stored through the existing Laravel filesystem architecture. The deployment
does not replace that architecture.

The Blueprint attaches a Render Persistent Disk and mounts the Laravel storage
directory for this single-instance deployment. The existing S3 disk remains an
alternative if the service later needs external object storage; configure it
and migrate existing files separately before changing `FILESYSTEM_DISK`.

The database stores file paths, not file contents. Moving the database alone
does not move avatars/images/proofs. Private subscription proofs must remain on
the private disk and continue using the authenticated download endpoint.

## Queues, cache, and logs

The Blueprint uses database cache/session settings and `QUEUE_CONNECTION=sync`
because the current application has no queue worker service configured. The
sessions migration is included for the database session table. If queued work
is introduced, add a separate Render worker running `php artisan queue:work`
and switch the queue connection deliberately.

Logs are sent to stderr for Render log collection. The existing Replit
workflow is unchanged.

## Deployment gate

Do not deploy the first production release until PostgreSQL credentials,
`APP_KEY`, `APP_URL`, CORS origins, and a durable upload strategy are chosen.
The first database migration and any SQLite data/file import remain deliberate
operator actions.