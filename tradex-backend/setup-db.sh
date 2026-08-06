#!/usr/bin/env bash
# One-time database bootstrap script.
# Run this AFTER MySQL is already started (via the MySQL workflow).
# Usage: bash setup-db.sh

set -e
SOCKET=/tmp/mysql/run/mysql.sock

echo "=== Waiting for MySQL socket... ==="
for i in $(seq 1 30); do
  if mysqladmin --socket="$SOCKET" -u root ping --silent 2>/dev/null; then
    echo "MySQL ready."
    break
  fi
  sleep 1
done

echo "=== Creating database + user ==="
mysql --socket="$SOCKET" -u root << 'SQL'
CREATE DATABASE IF NOT EXISTS tradx CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS 'tradx_user'@'127.0.0.1';
CREATE USER 'tradx_user'@'127.0.0.1' IDENTIFIED BY 'tradx_pass_2024';
GRANT ALL PRIVILEGES ON tradx.* TO 'tradx_user'@'127.0.0.1';
FLUSH PRIVILEGES;
SELECT 'Database and user created.' AS status;
SQL

echo "=== Running migrations ==="
cd "$(dirname "$0")"
php artisan migrate --force

echo "=== Seeding database ==="
php artisan db:seed --force

echo "=== Done! ==="
