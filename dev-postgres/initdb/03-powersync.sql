-- Creates a dedicated user and schema for PowerSync's bucket storage,
-- living inside the wger database (separate schema, no separate DB needed).
-- https://docs.powersync.com/configuration/powersync-service/self-hosted-instances#postgres-storage

-- The production dump may already contain a powersync schema. It is then owned
-- by the restoring superuser and its bucket storage state belongs to a different
-- Postgres instance anyway, so drop it and start clean.
DROP SCHEMA IF EXISTS powersync CASCADE;

CREATE USER powersync_storage WITH PASSWORD 'powersync_password';
CREATE SCHEMA powersync AUTHORIZATION powersync_storage;
GRANT CONNECT ON DATABASE wger TO powersync_storage;
