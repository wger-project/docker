#!/usr/bin/env bash
#
# Dumps the wger database (custom format) and keeps a rotating set of backups.
#
# Run from anywhere, configuration via environment variables (all optional):
#
#   COMPOSE_DIR       directory with the docker-compose.yml   (default: repo root)
#   BACKUP_DIR        where the dumps are stored              (default: /root/dumps)
#   DB_SERVICE        compose service of postgres             (default: db)
#   DB_USER / DB_NAME                                         (default: wger / wger)
#   DAILY_DAYS        delete daily dumps older than this      (default: 7)
#   WEEKLY_DAYS       same for the Sunday dumps               (default: 31)
#   MONTHLY_DAYS      same for the 1st-of-month dumps         (default: 186)
#
# Restore, see https://wger.readthedocs.io/en/latest/administration/backup.html

set -Eeuo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMPOSE_DIR=${COMPOSE_DIR:-$(dirname "$SCRIPT_DIR")}
BACKUP_DIR=${BACKUP_DIR:-/root/dumps}
DB_SERVICE=${DB_SERVICE:-db}
DB_USER=${DB_USER:-wger}
DB_NAME=${DB_NAME:-wger}
DAILY_DAYS=${DAILY_DAYS:-7}
WEEKLY_DAYS=${WEEKLY_DAYS:-31}
MONTHLY_DAYS=${MONTHLY_DAYS:-186}

log() { echo "$(date +'%F %T') $*"; }

trap 'log "Backup FAILED"' ERR

# mkdir is atomic, so this also works where flock is missing
LOCK_DIR="$BACKUP_DIR/.lock"
mkdir -p "$BACKUP_DIR"/{daily,weekly,monthly}
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log "Another backup is running (remove $LOCK_DIR if that is not the case)"
    exit 1
fi
trap 'rm -rf "$LOCK_DIR" "${TMP:-}"' EXIT

NAME="wger-$(date +'%F_%H%M').dump"
TMP="$BACKUP_DIR/daily/.$NAME.tmp"

log "Dumping database to $BACKUP_DIR/daily/$NAME"
cd "$COMPOSE_DIR"

# powersync.* is a cache rebuilt from the wger tables, sessions and thumbnails
# are regenerated as well
docker compose exec -T "$DB_SERVICE" pg_dump \
    --username "$DB_USER" \
    --format custom \
    --no-owner \
    --no-privileges \
    --exclude-schema=powersync \
    --exclude-table-data='public.django_session' \
    --exclude-table-data='public.easy_thumbnails_thumbnail' \
    --exclude-table-data='public.easy_thumbnails_source' \
    "$DB_NAME" > "$TMP"

# Reading the table of contents fails on a truncated or corrupt archive
docker compose exec -T "$DB_SERVICE" pg_restore --list < "$TMP" > /dev/null
mv "$TMP" "$BACKUP_DIR/daily/$NAME"
log "Dump OK, $(du -h "$BACKUP_DIR/daily/$NAME" | cut -f1)"

# Weekly and monthly sets are hard links, they cost no extra space
[[ $(date +%u) == 7 ]] && ln -f "$BACKUP_DIR/daily/$NAME" "$BACKUP_DIR/weekly/$NAME"
[[ $(date +%d) == 01 ]] && ln -f "$BACKUP_DIR/daily/$NAME" "$BACKUP_DIR/monthly/$NAME"

# Only reached after a successful dump, so a run of failures never empties a folder
find "$BACKUP_DIR/daily" -name 'wger-*.dump' -mtime +"$DAILY_DAYS" -print -delete
find "$BACKUP_DIR/weekly" -name 'wger-*.dump' -mtime +"$WEEKLY_DAYS" -print -delete
find "$BACKUP_DIR/monthly" -name 'wger-*.dump' -mtime +"$MONTHLY_DAYS" -print -delete

log "Backup finished"
