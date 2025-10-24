-- init/init.sql
-- Connect to the default postgres database
\connect postgres

-- Create the database dynamically based on environment variable
\echo "Creating database ${POSTGRES_DB} if it doesn't exist..."
\! psql -v ON_ERROR_STOP=1 -U ${POSTGRES_USER} -d postgres -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER}" 2>/dev/null || true

\echo "Database ${POSTGRES_DB} is ready."