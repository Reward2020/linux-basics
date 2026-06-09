#!/bin/bash
set -euo pipefail

DB_USER="${DB_USER:-goit}"
DB_NAME="${DB_NAME:-mytestdb}"
LOCKFILE="/tmp/pg_insert.lock"

usage() {
  cat <<EOF
Usage: $0 [-u db_user] [-d db_name] <user_list_file>

Options:
  -u    Database user (default: $DB_USER)
  -d    Database name (default: $DB_NAME)
EOF
  exit 1
}

cleanup() {
  rm -f "$LOCKFILE"
}
trap cleanup EXIT

while getopts ":u:d:" opt; do
  case $opt in
    u) DB_USER="$OPTARG" ;;
    d) DB_NAME="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND -1))

if [ "$#" -ne 1 ]; then
  usage
fi

USER_FILE="$1"

if [ ! -f "$USER_FILE" ]; then
  echo "File $USER_FILE does not exist!" >&2
  exit 3
fi

if [ -e "$LOCKFILE" ]; then
  echo "Script is already running!" >&2
  exit 2
fi
touch "$LOCKFILE"

is_valid_email() {
  local email="$1"
  [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

is_valid_username() {
  local username="$1"
  [[ "$username" =~ ^[a-zA-Z0-9_-]{1,30}$ ]]
}

# Функція для безпечного екранування рядка в SQL
sql_escape() {
  local s="$1"
  s="${s//\'/\'\'}"  # замінюємо ' на ''
  printf "'%s'" "$s"
}

while IFS=, read -r username email || [ -n "$username" ]; do
  username="${username// /}"
  email="${email// /}"

  if [[ -z "$username" ]]; then
    echo "Empty username, skipping"
    continue
  fi
  if ! is_valid_username "$username"; then
    echo "Invalid username '$username', skipping"
    continue
  fi

  if [[ -n "$email" ]] && ! is_valid_email "$email"; then
    echo "Invalid email '$email' for user '$username', skipping"
    continue
  fi

  esc_username=$(sql_escape "$username")
  if [[ -z "$email" ]]; then
    sql="INSERT INTO users (username) VALUES ($esc_username);"
  else
    esc_email=$(sql_escape "$email")
    sql="INSERT INTO users (username, email) VALUES ($esc_username, $esc_email);"
  fi

  if psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "$sql"; then
    if [[ -z "$email" ]]; then
      echo "Inserted: $username (no email)"
    else
      echo "Inserted: $username, $email"
    fi
  else
    echo "Failed to insert: $username" >&2
  fi

done < "$USER_FILE"
