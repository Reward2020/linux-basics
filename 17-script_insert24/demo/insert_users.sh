#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <user_list_file>"
  exit 1
}

cleanup() {
  rm -f "$LOCKFILE"
}
trap cleanup EXIT

LOCKFILE="/tmp/pg_insert.lock"
if [ -e "$LOCKFILE" ]; then
  echo "Script is already running!"
  exit 2
fi
touch "$LOCKFILE"

if [ "$#" -ne 1 ]; then
  usage
fi

USER_FILE="$1"

if [ ! -f "$USER_FILE" ]; then
  echo "File $USER_FILE does not exist!"
  exit 3
fi

while IFS=, read -r username email; do
  # Валідація імені
  if [[ -z "$username" ]]; then
    echo "Empty username, skipping"
    continue
  fi
  # Додавання в базу
  if [[ -z "$email" ]]; then
    psql -U goit -d mytestdb -c "INSERT INTO users (username) VALUES ('$username')" \
      && echo "Inserted: $username (no email)" \
      || echo "Failed to insert: $username"
  else
    psql -U goit -d mytestdb -c "INSERT INTO users (username, email) VALUES ('$username', '$email')" \
      && echo "Inserted: $username, $email" \
      || echo "Failed to insert: $username"
  fi
done < "$USER_FILE"
