-- Creates a dedicated user and schema for PowerSync's bucket storage,
-- living inside the wger database (separate schema, no separate DB needed).
-- https://docs.powersync.com/configuration/powersync-service/self-hosted-instances#postgres-storage

CREATE USER powersync_storage_user WITH PASSWORD 'secure_password';
CREATE SCHEMA IF NOT EXISTS powersync AUTHORIZATION powersync_storage_user;
GRANT CONNECT ON DATABASE wger TO powersync_storage_user;
GRANT USAGE ON SCHEMA powersync TO powersync_storage_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA powersync TO powersync_storage_user;