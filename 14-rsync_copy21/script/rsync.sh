#!/bin/bash

CONFIG_DIR="$HOME/Documents/GOIT/rsync"
WATCH_DIR="$HOME/Documents/GOIT/rsync"
REMOTE_HOST="goit-server"    # ім'я з ssh config, ваш аліас
REMOTE_HOME=$(ssh "$REMOTE_HOST" 'echo $HOME')
REMOTE_PATH="${REMOTE_HOME}/app"

echo "Віддалена домашня директорія: $REMOTE_HOME"
echo "Віддалений шлях для деплою: $REMOTE_PATH"
echo "============================================================="

generate_function_json() {
  local conf_file="$1"
  local base_name=$(basename "$conf_file" .conf)
  local output_json="${CONFIG_DIR}/function_${base_name}.json"

  declare -A env_vars

  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    env_vars[$key]=$value
  done < "$conf_file"

  json_parts=()
  for key in "${!env_vars[@]}"; do
    if [[ "$key" == "LABELS" ]]; then
      IFS=',' read -ra label_pairs <<< "${env_vars[LABELS]}"
      labels_json_parts=()
      for pair in "${label_pairs[@]}"; do
        IFS='=' read -ra kv <<< "$pair"
        k="${kv[0]}"
        v="${kv[1]}"
        labels_json_parts+=("\"$k\":\"$v\"")
      done
      labels_json="{$(IFS=,; echo "${labels_json_parts[*]}")}"
      json_parts+=("\"labels\": $labels_json")
    else
      val="${env_vars[$key]}"
      json_parts+=("\"$key\": \"$val\"")
    fi
  done

  json_content="{$(IFS=,; echo "${json_parts[*]}")}"

  echo "$json_content" > "$output_json"
  echo "Згенеровано $output_json:"
  cat "$output_json"
  echo
}

shopt -s nullglob
conf_files=("$CONFIG_DIR"/*.conf)
if [ ${#conf_files[@]} -eq 0 ]; then
  echo "Файли конфігурації не знайдені"
  exit 1
fi

for conf_file in "${conf_files[@]}"; do
  generate_function_json "$conf_file"
done
shopt -u nullglob

echo "Копіюємо function_*.json на сервер..."
scp "$CONFIG_DIR"/function_*.json ${REMOTE_HOST}:${REMOTE_PATH}/
# Або можемо використати так
# rsync -av "$CONFIG_DIR"/function_*.json ${REMOTE_HOST}:${REMOTE_PATH}/

echo -e "\n--- Dry-run: Перевірка файлів для синхронізації ---"
rsync -av --dry-run --exclude='.git/' --exclude='node_modules/' "$WATCH_DIR/" ${REMOTE_HOST}:${REMOTE_PATH}/rsync/

read -p "Виконати реальну синхронізацію? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Виконуємо деплой..."
  rsync -av --exclude='.git/' --exclude='node_modules/' "$WATCH_DIR/" ${REMOTE_HOST}:${REMOTE_PATH}/rsync/
  echo "Деплой завершено."
else
  echo "Деплой скасовано."
fi
