#!/usr/bin/env sh

set -e

APP_ROOT=/var/www/html
PORT="${PORT:-8000}"

# ──────────────────────────────────────────────────────────────────────────────
# Start both PHP server and queue worker in the same container.
# Both processes run in the background with proper signal handling.
# Render detects HTTP availability via the PHP server port binding.
# Queue worker processes jobs from the database table continuously.
# ──────────────────────────────────────────────────────────────────────────────

# PID of background PHP process
PHP_PID=""

# Handle graceful shutdown on TERM (Render) and INT (Ctrl+C)
# POSIX sh syntax: use TERM INT (not SIGTERM SIGINT)
on_signal() {
    echo "[container] Received shutdown signal, gracefully stopping PHP server..."

    if [ -n "$PHP_PID" ] && kill -0 "$PHP_PID" 2>/dev/null; then
        echo "[container] Stopping PHP server (PID $PHP_PID)..."
        kill -TERM "$PHP_PID" 2>/dev/null || true
        wait "$PHP_PID" 2>/dev/null || true
    fi

    exit 0
}

trap on_signal TERM INT

echo "[container] Starting Tradex backend..."
echo "[container] HTTP server will bind to 0.0.0.0:$PORT"

cd "$APP_ROOT"

# Start PHP built-in server in the background
echo "[container] Starting PHP server on port $PORT..."
php -S 0.0.0.0:$PORT -t public docker/router.php &
PHP_PID=$!
echo "[container] PHP server started (PID $PHP_PID)"

# Give PHP server a moment to bind to the port (Render needs to detect it)
sleep 2

# Verify PHP server is still running
if ! kill -0 "$PHP_PID" 2>/dev/null; then
    echo "[container] FATAL: PHP server failed to start"
    exit 1
fi

# Wait for the PHP HTTP process only. The dedicated Render worker service handles
# queue processing using `php artisan queue:work database`.
wait "$PHP_PID"
