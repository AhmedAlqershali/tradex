#!/usr/bin/env sh

set -eu

APP_ROOT=/var/www/html
PORT="${PORT:-8000}"
PHP_PID=""
QUEUE_PID=""
SHUTTING_DOWN=0

process_is_running() {
    [ -d "/proc/$1" ] || return 1
    [ "$(cat "/proc/$1/stat" 2>/dev/null | cut -d ' ' -f 3)" != "Z" ]
}

stop_processes() {
    if [ -n "$PHP_PID" ] && process_is_running "$PHP_PID"; then
        kill -TERM "$PHP_PID" 2>/dev/null || true
    fi
    if [ -n "$QUEUE_PID" ] && process_is_running "$QUEUE_PID"; then
        kill -TERM "$QUEUE_PID" 2>/dev/null || true
    fi
}

on_signal() {
    SHUTTING_DOWN=1
    echo "[container] Received shutdown signal; stopping HTTP server and queue worker..." >&2
    stop_processes
    wait "$PHP_PID" 2>/dev/null || true
    wait "$QUEUE_PID" 2>/dev/null || true
    exit 0
}

trap on_signal TERM INT

cd "$APP_ROOT"

echo "[container] Starting HTTP server on 0.0.0.0:$PORT..." >&2
php -S "0.0.0.0:$PORT" -t public docker/router.php &
PHP_PID=$!

echo "[container] Starting queue worker: php artisan queue:work database..." >&2
php artisan queue:work database &
QUEUE_PID=$!

echo "[container] HTTP server PID: $PHP_PID; queue worker PID: $QUEUE_PID" >&2

while :; do
    if ! process_is_running "$PHP_PID"; then
        if [ "$SHUTTING_DOWN" -eq 0 ]; then
            echo "[container] FATAL: HTTP server exited unexpectedly" >&2
            stop_processes
            wait "$PHP_PID" 2>/dev/null || true
            wait "$QUEUE_PID" 2>/dev/null || true
            exit 1
        fi
    fi

    if ! process_is_running "$QUEUE_PID"; then
        if [ "$SHUTTING_DOWN" -eq 0 ]; then
            echo "[container] FATAL: queue worker exited unexpectedly" >&2
            stop_processes
            wait "$PHP_PID" 2>/dev/null || true
            wait "$QUEUE_PID" 2>/dev/null || true
            exit 1
        fi
    fi

    sleep 1
done
