#!/bin/bash
set -e

# Шлях у системній директорії 
SSH_ALIAS="goit-server"
APP_DIR="/home/goit/apps/my-app"

# Опції SSH з ігноруванням банерів та вимкненим stdin
SSH_OPTS="-q -n -T -o LogLevel=QUIET -o ConnectTimeout=5"

echo "🌐 [1/4] Перевірка Docker Compose на віртуальній машині..."
ssh $SSH_OPTS $SSH_ALIAS < prepare_step1.sh

echo "📁 [2/4] Підготовка структури папок у /opt..."
# Оскільки ми вже дали права на папку користувачу goit на ВМ, step2 відпрацює без проблем
ssh $SSH_ALIAS "bash -s" < prepare_step2.sh "$APP_DIR"

echo "📄 [3/4] Копіювання конфігурації та коду гри через SCP..."
# Копіюємо БЕЗ sudo перед scp. Файли летять напряму в підготовлену папку /opt
scp -q -o LogLevel=QUIET docker-compose.yml $SSH_ALIAS:$APP_DIR/docker-compose.yml
scp -q -r -o LogLevel=QUIET game_code $SSH_ALIAS:$APP_DIR/

echo "🚀 [4/4] Запуск простого веб-сайту в Ubuntu 24.04..."
# Зачищаємо старе та піднімаємо Docker Compose
ssh $SSH_OPTS $SSH_ALIAS "cd $APP_DIR && docker compose down --remove-orphans 2>/dev/null || true"
ssh $SSH_OPTS $SSH_ALIAS "cd $APP_DIR && docker compose up -d"

echo "--------------------------------------------------------"
echo "🎉 Деплой успішно завершено!"
echo "🎮 Гра доступна за адресою: http://localhost:8082"
echo "(Переконайся, що у VirtualBox NAT прокинуто порт 8082 -> 8082)"
