#!/usr/bin/env bash

function abort() {
  printf "Fatal: %s\n" "$1"
  exit 1
}

DEBUG=${DEBUG:-0}

if [ "$DEBUG" -gt 0 ]; then
  env
  cat /config/rclone/rclone.conf
fi

if [ -z "$SRC_REMOTE" ]; then
  abort "SRC_REMOTE is not set"
fi

if [ -z "$DST_REMOTE" ]; then
  abort "DST_REMOTE is not set"
fi

if [ -z "$SRC_BUCKET" ]; then
  abort "SRC_BUCKET is not set"
fi

if [ -z "$DST_BUCKET" ]; then
  abort "DST_BUCKET is not set"
fi

TIMESTAMP=$(date -u +%s)
SRC_DIR=${SRC_DIR:-"."}
DST_DIR=${DST_DIR:-"s3"}
SRC="$SRC_REMOTE:$SRC_BUCKET"
DST="$DST_REMOTE:$DST_BUCKET/$DST_DIR/$TIMESTAMP"

printf "Copy from %s to %s\n" "$SRC" "$DST"
rclone --progress copy "$SRC" "$DST" || abort "An error occurred while copying files"

if [ "$BACKUP_TTL" -gt 0 ]; then
  printf "Proceeding to purge old backups (BACKUP_TTL is %s seconds)\n" "$BACKUP_TTL"

  ALL_BACKUPS=$(rclone lsjson "$DST_REMOTE:$DST_BUCKET/$DST_DIR" | jq -r .[].Name)
  printf "Total backups found: %s\n" "$(echo "$ALL_BACKUPS" | wc -l)"

  for BACKUP in $ALL_BACKUPS; do
    # convert iso datetime string to epoch seconds and subtract to get the age in seconds
    BACKUP_AGE=$((TIMESTAMP - BACKUP))
    if [ "$BACKUP_AGE" -gt "$BACKUP_TTL" ]; then
      printf "Purge %s (age %d is greater than %d)\n" "$BACKUP" "$BACKUP_AGE" "$BACKUP_TTL"
      rclone --progress purge "$DST_REMOTE:$DST_BUCKET/$DST_DIR/$BACKUP"
    elif [ "$DEBUG" -gt 0 ]; then
      printf "No purge needed for %s (age %d is less than %d)\n" "$BACKUP" "$BACKUP_AGE" "$BACKUP_TTL"
    fi
  done
else
  printf "BACKUP_TTL is invalid or not set. no backups will be purged\n"
fi
