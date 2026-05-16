# Monitoring with grafana

This folder contains a pre-configured grafana instance. Basically just
start the docker compose file.

Please consult the documentation at https://wger.readthedocs.io/en/latest/administration/monitoring.html

## Read-only Postgres user for Grafana

Grafana doesn't validate the SQL it executes, so a panel or anyone with edit
rights could run `DROP TABLE`, `DELETE`, etc. against the database. The provisioned
postgres datasource points at a dedicated read-only role (`grafana_ro`), which **you
need to create once** before Grafana starts:

```sh
docker exec -i docker-db-1 psql -U wger -d wger <<'SQL'
CREATE ROLE grafana_ro WITH LOGIN PASSWORD 'grafana_ro';
GRANT CONNECT ON DATABASE wger TO grafana_ro;
GRANT USAGE ON SCHEMA public TO grafana_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_ro;

-- Cover tables created by future Django migrations:
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO grafana_ro;
SQL
```

If you need to remove access:

```sql
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM grafana_ro;
REVOKE ALL ON SCHEMA public FROM grafana_ro;
REVOKE ALL ON DATABASE wger FROM grafana_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT ON TABLES FROM grafana_ro;
DROP ROLE grafana_ro;
```
