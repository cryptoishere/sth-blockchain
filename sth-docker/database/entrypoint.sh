#!/bin/bash
set -e

DATA_DIR="${PGDATA:-/var/lib/postgresql/18/blockchain}"
POSTGRES_USER="${POSTGRES_USER:-sth}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password}"
POSTGRES_DB="${POSTGRES_DB:-sth_mainnet}"

# Clean old data if desired
# rm -rf "$DATA_DIR"/*

# Initialize DB if empty
if [ ! -f "$DATA_DIR/PG_VERSION" ]; then
    echo "Initializing database..."
    # Don't override initdb username
    gosu postgres initdb -D "$DATA_DIR" -A md5 --auth-local=trust --auth-host=md5

    # Allow remote password access from your network
    echo "host all all 10.10.10.0/24 md5" >> "$DATA_DIR/pg_hba.conf"

    # Start Postgres temporarily
    echo "Starting Postgres temporarily to create 'postgres' superuser and run init scripts..."
    gosu postgres pg_ctl -D "$DATA_DIR" -o "-c listen_addresses='localhost'" -w start

    # Create superuser 'postgres' if it doesn't exist
    gosu postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        DO
        \$do\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'postgres') THEN
                CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD '$POSTGRES_PASSWORD';
            END IF;
        END
        \$do\$;
EOSQL

    # Create your user if it doesn't exist
    gosu postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        DO
        \$do\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_USER') THEN
                CREATE ROLE "$POSTGRES_USER" LOGIN PASSWORD '$POSTGRES_PASSWORD';
            END IF;
        END
        \$do\$;
EOSQL

    # Create your database if it doesn't exist
    gosu postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        SELECT 'CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$POSTGRES_DB')\gexec
EOSQL

    # Run init scripts
    for f in /docker-entrypoint-initdb.d/*; do
        case "$f" in
            *.sh)  gosu postgres bash "$f" ;;
            *.sql) gosu postgres psql -v ON_ERROR_STOP=1 -d "$POSTGRES_DB" -f "$f" ;;
            *.dump) gosu postgres pg_restore -d "$POSTGRES_DB" "$f" ;;
            *) echo "Skipping $f" ;;
        esac
    done

    # Stop temporary server
    gosu postgres pg_ctl -D "$DATA_DIR" -m fast -w stop
fi

# Start Postgres for real (PID 1)
exec gosu postgres postgres -D "$DATA_DIR" -c listen_addresses='0.0.0.0'