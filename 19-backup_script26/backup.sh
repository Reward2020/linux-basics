#!/bin/bash
# backup.sh - Скрипт для резервного копіювання директорії
# Автор: Ivan Ivanov
# Дата: 2026-06-01
# Використання: ./backup.sh -s /source/dir -d /backup/dir

set -euo pipefail
IFS=$'\n\t'

print_usage() {
  echo "Використання: $0 -s <source_dir> -d <backup_dir>"
}

log() {
  local level="$1"
  local msg="$2"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg"
}

SOURCE_DIR=""
BACKUP_DIR=""

while getopts "s:d:h" opt; do
  case "$opt" in
    s) SOURCE_DIR="$OPTARG" ;;
    d) BACKUP_DIR="$OPTARG" ;;
    h) print_usage; exit 0 ;;
    *) print_usage; exit 1 ;;
  esac
done

if [[ -z "$SOURCE_DIR" || -z "$BACKUP_DIR" ]]; then
  log "ERROR" "Не вказані обов’язкові параметри"
  print_usage
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  log "ERROR" "Джерело не існує: $SOURCE_DIR"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

DATE=$(date +'%Y-%m-%d_%H-%M-%S')
BACKUP_FILE="${BACKUP_DIR}/backup_${DATE}.tar.gz"

log "INFO" "Початок бекапу $SOURCE_DIR у $BACKUP_FILE"

tar czf "$BACKUP_FILE" -C "$SOURCE_DIR" .

log "INFO" "Бекап завершено успішно"
