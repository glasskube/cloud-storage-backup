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

NEW_BACKUP=$(date -u +%s)
SRC_DIR=${SRC_DIR:-"."}
DST_DIR=${DST_DIR:-"s3"}
SRC="$SRC_REMOTE:$SRC_BUCKET"
DST_ROOT="$DST_REMOTE:$DST_BUCKET/$DST_DIR"
DST="$DST_ROOT/$NEW_BACKUP"

ALL_BACKUPS=$(rclone lsjson "$DST_ROOT" | jq -r .[].Name)
printf "Existing backups found: %s\n" "$(echo "$ALL_BACKUPS" | wc -l)"

LATEST_BACKUP=0
for BACKUP in $ALL_BACKUPS; do
  if [ "$BACKUP" -gt "$LATEST_BACKUP" ]; then
    LATEST_BACKUP="$BACKUP"
  fi
done

if [ "$LATEST_BACKUP" -gt 0 ]; then
  printf "Latest existing backup is %s. Sync to %s\n" "$LATEST_BACKUP" "$DST"
  rclone --verbose --progress sync "$DST_ROOT/$LATEST_BACKUP" "$DST" || printf "An error occurred while syncing from latest backup\n"
else
  printf "No existing backup found.\n"
fi

printf "Sync changes from %s to %s\n" "$SRC" "$DST"
rclone --verbose --progress sync "$SRC" "$DST" || abort "An error occurred while syncing from source"

BACKUP_TTL=${BACKUP_TTL:-0}

if [ "$BACKUP_TTL" -gt 0 ]; then
  printf "Proceeding to purge old backups (BACKUP_TTL is %s seconds)\n" "$BACKUP_TTL"

  for BACKUP in $ALL_BACKUPS; do
    # convert iso datetime string to epoch seconds and subtract to get the age in seconds
    BACKUP_AGE=$((NEW_BACKUP - BACKUP))
    if [ "$BACKUP_AGE" -gt "$BACKUP_TTL" ]; then
      printf "Purge %s (age %d is greater than %d)\n" "$BACKUP" "$BACKUP_AGE" "$BACKUP_TTL"
      rclone --verbose --progress purge "$DST_ROOT/$BACKUP"
    elif [ "$DEBUG" -gt 0 ]; then
      printf "No purge needed for %s (age %d is less than %d)\n" "$BACKUP" "$BACKUP_AGE" "$BACKUP_TTL"
    fi
  done
else
  printf "BACKUP_TTL is invalid or not set. no backups will be purged\n"
fi
