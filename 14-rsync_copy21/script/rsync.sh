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

  # echo "{" > "$output_json" — починаємо формувати JSON-об’єкт
  echo "{" > "$output_json"
  # first=1 потрібна, щоб правильно розставити коми між полями JSON
  local first=1

  while IFS= read -r line; do
    # Пропускаємо порожні рядки та коментарі
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    key="${line%%=*}"
    value="${line#*=}"

    if [ "$key" = "LABELS" ]; then
      # Формуємо labels як вкладений об'єкт
      if [ $first -eq 0 ]; then
        echo "," >> "$output_json"
      fi
      echo -n '  "labels": {' >> "$output_json"

      IFS=',' read -ra label_pairs <<< "$value"
      local label_first=1
      for pair in "${label_pairs[@]}"; do
        label_key="${pair%%=*}"
        label_value="${pair#*=}"
        if [ $label_first -eq 0 ]; then
          echo -n "," >> "$output_json"
        fi
        echo -n "\"$label_key\":\"$label_value\"" >> "$output_json"
        # Після першого поля first стає 0, і перед наступними полями додається кома.
        label_first=0
      done

      echo -n "}" >> "$output_json"
    else
      if [ $first -eq 0 ]; then
        echo "," >> "$output_json"
      fi
      echo -n "  \"$key\":\"$value\"" >> "$output_json"
    fi

    first=0
  done < "$conf_file"

  echo -e "\n}" >> "$output_json"

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
rsync -av --dry-run --exclude='.git/' --exclude='node_modules/' "$WATCH_DIR/" ${REMOTE_HOST}:${REMOTE_PATH}/rsync

read -p "Виконати реальну синхронізацію? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Виконуємо деплой..."
  rsync -av --exclude='.git/' --exclude='node_modules/' "$WATCH_DIR/" ${REMOTE_HOST}:${REMOTE_PATH}/rsync
  echo "Деплой завершено."
else
  echo "Деплой скасовано."
fi
