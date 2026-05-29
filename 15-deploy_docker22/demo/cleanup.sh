#!/bin/bash
# Скрипт повного очищення віртуальної машини перед демонстрацією

SSH_ALIAS="goit-server" # потрібно замінити на ваш аліас для підключення до серверу
APP_DIR="/opt/apps/my-app"
SSH_OPTS="-q -n -T -o LogLevel=QUIET -o ConnectTimeout=5"

echo "🧹 [1/3] Зупинка контейнерів та видалення мереж..."
ssh $SSH_OPTS $SSH_ALIAS "cd $APP_DIR 2>/dev/null && sudo docker compose down --volumes --remove-orphans 2>/dev/null || true"

echo "🗑️ [2/3] Видалення папок з кодом та конфігураціями на ВМ..."
# Видаляємо стару папку в /opt (якщо залишилась) та нову в домашній директорії
ssh $SSH_OPTS $SSH_ALIAS "sudo rm -rf /opt/my-app $APP_DIR"

echo "🧼 [3/3] Очищення системного кешу Docker (Prune)..."
# Видаляємо невикористовувані контейнери та мережі, щоб звільнити систему
ssh $SSH_OPTS $SSH_ALIAS "sudo docker system prune -f 2>/dev/null || true"

echo "--------------------------------------------------------"
echo "✨ Віртуальна машина повністю очищена і готова до деплою!"
