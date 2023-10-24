#!/usr/bin/env bash

set -e

log_debug() {
  if [ "$DEBUG" -gt 0 ]; then
    echo "DEBUG: $*" >&2
  fi
}

log_info() {
  echo "INFO: $*" >&2
}

log_warn() {
  echo "WARN: $*" >&2
}

abort() {
  echo "FATAL: $*" >&2
  exit 1
}

DEBUG=${DEBUG:-0}

if [ "$DEBUG" -gt 0 ]; then
  env
  rclone config show ||
    log_warn "rclone config could not be shown"
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
ALL_BACKUPS=$(rclone --verbose lsjson "$DST_ROOT" || abort "error reading from DST_REMOTE")
ALL_BACKUPS=$(echo "$ALL_BACKUPS" | jq -r .[].Name)
log_info "Existing backups found: $(echo "$ALL_BACKUPS" | wc -l)"

LATEST_BACKUP=0
for BACKUP in $ALL_BACKUPS; do
  if [ "$BACKUP" -gt "$LATEST_BACKUP" ]; then
    LATEST_BACKUP="$BACKUP"
  fi
done

if [ "$LATEST_BACKUP" -gt 0 ]; then
  log_info "Latest existing backup is $LATEST_BACKUP. Sync to $DST."
  rclone --verbose sync "$DST_ROOT/$LATEST_BACKUP" "$DST" ||
    log_warn "An error occurred while syncing from latest backup."
else
  log_info "No existing backup found."
fi

log_info "Sync changes from $SRC to $DST"
rclone --verbose sync "$SRC" "$DST" ||
  abort "An error occurred while syncing from source"

BACKUP_TTL=${BACKUP_TTL:-0}

if [ "$BACKUP_TTL" -gt 0 ]; then
  log_info "Proceeding to purge old backups (BACKUP_TTL is $BACKUP_TTL seconds)."

  for BACKUP in $ALL_BACKUPS; do
    # convert iso datetime string to epoch seconds and subtract to get the age in seconds
    BACKUP_AGE=$((NEW_BACKUP - BACKUP))
    if [ "$BACKUP_AGE" -gt "$BACKUP_TTL" ]; then
      log_info "Purge $BACKUP (age $BACKUP_AGE is greater than $BACKUP_TTL)."
      rclone --verbose purge "$DST_ROOT/$BACKUP" ||
        log_warn "Error trying to purge $BACKUP."
    else
      log_debug "No purge needed for $BACKUP (age $BACKUP_AGE is less than $BACKUP_TTL)."
    fi
  done
else
  log_info "BACKUP_TTL is invalid or not set. no backups will be purged."
fi
