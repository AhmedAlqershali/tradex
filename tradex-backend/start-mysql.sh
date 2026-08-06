#!/usr/bin/env bash
# MySQL startup script for Replit development
# Keeps mysqld in the foreground so the workflow stays alive.

set -e

MYSQL_DIR=/tmp/mysql
DATADIR=$MYSQL_DIR/data
RUNDIR=$MYSQL_DIR/run
LOGDIR=$MYSQL_DIR/log
TMPDIR=$MYSQL_DIR/tmp

mkdir -p "$DATADIR" "$RUNDIR" "$LOGDIR" "$TMPDIR"

# Write config
cat > "$MYSQL_DIR/my.cnf" << 'MYCNF'
[mysqld]
datadir=/tmp/mysql/data
socket=/tmp/mysql/run/mysql.sock
pid-file=/tmp/mysql/run/mysql.pid
log-error=/tmp/mysql/log/error.log
tmpdir=/tmp/mysql/tmp
port=3306
bind-address=127.0.0.1
skip-mysqlx
[client]
socket=/tmp/mysql/run/mysql.sock
MYCNF

# Initialize data directory on first run
if [ ! -d "$DATADIR/mysql" ]; then
  echo "[start-mysql] Initializing data directory..."
  mysqld --initialize-insecure \
    --user="$(whoami)" \
    --datadir="$DATADIR" \
    2>&1
  echo "[start-mysql] Initialization complete."
fi

echo "[start-mysql] Starting mysqld..."
exec mysqld --defaults-file="$MYSQL_DIR/my.cnf"
