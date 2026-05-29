#!/bin/bash
set -e

# Шлях у системній директорії /opt
SSH_ALIAS="goit-server"
APP_DIR="/opt/apps/my-app"

# Опції SSH з ігноруванням банерів та вимкненим stdin
SSH_OPTS="-t -o LogLevel=QUIET -o ConnectTimeout=5" # Прибрав -q -n -T щоб можна було побачити логи -t щоб було в одному TTY але не прихований вивід

echo "🌐 [1/4] Перевірка Docker Compose на віртуальній машині..."
ssh $SSH_OPTS $SSH_ALIAS < prepare_step1.sh

echo "📁 [2/4] Підготовка структури папок in /opt..."
# Оскільки ми вже дали права на папку користувачу goit на ВМ, step2 відпрацює без проблем
ssh $SSH_OPTS $SSH_ALIAS "bash -s" -- "$APP_DIR" < prepare_step2.sh # -- — означає кінець опцій для bash. "$APP_DIR" — передається як перший аргумент у скрипт.

echo "📄 [3/4] Копіювання конфігурації та коду гри через SCP..."
# Копіюємо БЕЗ sudo перед scp. Файли летять напряму в підготовлену папку /opt
scp -q -o LogLevel=QUIET docker-compose.yml $SSH_ALIAS:$APP_DIR/docker-compose.yml
scp -q -r -o LogLevel=QUIET game_code $SSH_ALIAS:$APP_DIR/

echo "🚀 [4/4] Запуск простого веб-сайту в Ubuntu 24.04..."
# Зачищаємо старе та піднімаємо Docker Compose
ssh $SSH_OPTS $SSH_ALIAS "cd $APP_DIR && sudo docker compose down --remove-orphans 2>/dev/null || true"
ssh $SSH_OPTS $SSH_ALIAS "cd $APP_DIR && sudo docker compose up -d"

echo "--------------------------------------------------------"
echo "🎉 Деплой успішно завершено!"
echo "🎮 Гра доступна за адресою: http://localhost:8082"
echo "(Переконайся, що in VirtualBox NAT прокинуто порт 8082 -> 8082)"
