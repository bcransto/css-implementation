#!/usr/bin/env bash
# Nightly SQLite backup. Runs at 1:50 AM (10 minutes before ranchero pulls
# pinto at 2:00 AM) so the consistent snapshot ends up in ranchero's archive.
#
# Wire it on the Pi with:
#   ( crontab -l 2>/dev/null; echo "50 1 * * * /home/bcransto/css-implementation/deploy/backup.sh" ) | crontab -

set -euo pipefail

DB="/home/bcransto/css-implementation/css.db"
DEST_DIR="/home/bcransto/backups"
KEEP=3

mkdir -p "$DEST_DIR"

DATE=$(date +%F-%H%M)
DEST="$DEST_DIR/css-tiers-$DATE.db"

sqlite3 "$DB" ".backup '$DEST'"

# Keep only the most recent $KEEP backups locally; ranchero is the long-term archive.
ls -1t "$DEST_DIR"/css-tiers-*.db | tail -n +$((KEEP + 1)) | xargs -r rm -f
