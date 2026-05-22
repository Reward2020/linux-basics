#!/bin/bash
if ! docker compose version &>/dev/null; then
  echo "!!! Docker Compose не знайдено. Встановлюємо пакет docker-compose-v2..."
  sudo apt update && sudo apt install -y docker.io docker-compose-v2
else
  echo "OK, Docker Compose вже інстальовано."
fi

# У випадку встановлення у Вас докера за допомогою снап то видаліть та запустіть основний скрипт
# sudo snap remove --purge docker
