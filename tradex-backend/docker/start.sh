#!/usr/bin/env sh

set -e

APP_ROOT=/var/www/html
PORT="${PORT:-8000}"

# ──────────────────────────────────────────────────────────────────────────────
# Start both PHP server and queue worker in the same container.
# This script manages process lifecycle so both stay running, and signals are
# passed correctly when the container needs to shut down.
# ──────────────────────────────────────────────────────────────────────────────

# Flag to track if shutdown is in progress
SHUTDOWN=0

# Handle SIGTERM (Render/Kubernetes graceful shutdown) and SIGINT (Ctrl+C)
on_signal() {
    echo "[container] Received shutdown signal, gracefully stopping both processes..."
    SHUTDOWN=1
    
    # Kill the background PHP server
    if [ -n "$PHP_PID" ] && kill -0 "$PHP_PID" 2>/dev/null; then
        echo "[container] Stopping PHP server (PID $PHP_PID)..."
        kill -TERM "$PHP_PID" 2>/dev/null || true
        wait "$PHP_PID" 2>/dev/null || true
    fi
    
    # Kill the foreground queue worker (it will handle the signal itself)
    # The trap in the queue worker command will catch TERM
    exit 0
}

trap on_signal SIGTERM SIGINT

echo "[container] Starting Tradex backend..."
echo "[container] HTTP server will bind to 0.0.0.0:$PORT"
echo "[container] Queue worker will process database jobs"

# Start PHP built-in server in the background
echo "[container] Starting PHP server..."
cd "$APP_ROOT"
php -S 0.0.0.0:$PORT -t public docker/router.php &
PHP_PID=$!
echo "[container] PHP server started (PID $PHP_PID)"

# Give the PHP server a moment to bind to the port
sleep 1

# Verify PHP server is still running
if ! kill -0 "$PHP_PID" 2>/dev/null; then
    echo "[container] ERROR: PHP server failed to start"
    exit 1
fi

echo "[container] Starting queue worker..."

# Start queue worker in the foreground (with trap for graceful shutdown)
# Using --timeout=60 and --tries=3 per the documented recommendation
# The --max-jobs prevents unbounded memory growth
php artisan queue:work database \
    --sleep=3 \
    --tries=3 \
    --timeout=60 \
    --max-jobs=1000

# queue:work exited; this is a failure scenario in production
echo "[container] ERROR: Queue worker exited unexpectedly"
kill -TERM "$PHP_PID" 2>/dev/null || true
exit 1
