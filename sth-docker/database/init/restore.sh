#!/bin/bash
set -e

# Define database variables explicitly
DB_NAME="${POSTGRES_DB:-sth_mainnet}"
DB_USER="${POSTGRES_USER:-sth}"
DUMP_FILE="/docker-entrypoint-initdb.d/sth_mainnet.dump"

# Only run if the database is empty
DB_EXISTS=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
if [ "$DB_EXISTS" != "1" ]; then
    echo "Restoring database $DB_NAME from dump..."
    createdb -U "$DB_USER" "$DB_NAME"
    pg_restore -U "$DB_USER" -d "$DB_NAME" "$DUMP_FILE"
    echo "Database $DB_NAME restored successfully."
else
    echo "Database $DB_NAME already exists. Skipping restore."
fi