#!/bin/bash

SERVICE_NAME="logmonitor"
LOG_DIR="/var/log"
COLLECT_DIR="/var/logs/$SERVICE_NAME"
COLLECTED_LOG="$COLLECT_DIR/collected.log"
MONITOR_SCRIPT="/usr/local/bin/log_monitor.sh"
USER_NAME="$SERVICE_NAME"
GROUP_NAME="adm"

# usage() {
#   echo "Використання: $0 [--service_name NAME] [--log_dir PATH] [--monitor_script PATH]"
#   exit 1
# }

# # Парсинг аргументів
# while [[ $# -gt 0 ]]; do
#   key="$1"
#   case $key in
#     --service_name)
#       SERVICE_NAME="$2"
#       USER_NAME="$SERVICE_NAME"
#       shift 2
#       ;;
#     --log_dir)
#       LOG_DIR="$2"
#       shift 2
#       ;;
#     --monitor_script)
#       MONITOR_SCRIPT="$2"
#       shift 2
#       ;;
#     -h|--help)
#       usage
#       ;;
#     *)
#       echo "Невідомий параметр: $1"
#       usage
#       ;;
#   esac
# done

echo "Параметри:"
echo "SERVICE_NAME = $SERVICE_NAME"
echo "LOG_DIR = $LOG_DIR"
echo "COLLECT_DIR = $COLLECT_DIR"
echo "COLLECTED_LOG = $COLLECTED_LOG"
echo "MONITOR_SCRIPT = $MONITOR_SCRIPT"
echo "USER_NAME = $USER_NAME"
echo "GROUP_NAME = $GROUP_NAME"

# Перевірка, чи скрипт запущено з правами root
if [[ $EUID -ne 0 ]]; then
   echo "Цей скрипт потрібно запускати з правами root" 
   exit 1
fi

echo "Створюємо користувача $USER_NAME (якщо не існує)..."
if id "$USER_NAME" &>/dev/null; then
    echo "Користувач $USER_NAME вже існує"
else
    useradd --system --no-create-home --group $GROUP_NAME $USER_NAME
    echo "Користувач $USER_NAME створений"
fi

echo "Створюємо директорію для збору логів $COLLECT_DIR..."
mkdir -p "$COLLECT_DIR"
chown -R $USER_NAME:$GROUP_NAME "$COLLECT_DIR"
chmod 750 "$COLLECT_DIR"
echo "Директорія $COLLECT_DIR створена та налаштована"

echo "Створюємо файл для колекціонування логів $COLLECTED_LOG..."
touch "$COLLECTED_LOG"
chown $USER_NAME:$GROUP_NAME "$COLLECTED_LOG"
chmod 640 "$COLLECTED_LOG"

echo "Створюємо скрипт моніторингу $MONITOR_SCRIPT..."
cat > "$MONITOR_SCRIPT" << EOF
#!/bin/bash

LOG_DIR="$LOG_DIR"
COLLECTED_LOG="$COLLECTED_LOG"
SLEEP_INTERVAL=5

declare -A offsets

while true; do
  for logfile in "\$LOG_DIR"/*.log; do
    # Пропускаємо зібраний лог, якщо він в тому ж каталозі
    if [[ "\$logfile" == "\$COLLECTED_LOG" ]]; then
      continue
    fi
    # Перевіряємо, чи файл існує
    [[ -f "\$logfile" ]] || continue

    # Отримуємо розмір файлу
    filesize=\$(stat --printf="%s" "\$logfile")

    # Ініціалізація offset, якщо немає
    if [[ -z "\${offsets[\$logfile]}" ]]; then
      offsets[\$logfile]=0
    fi
    # Якщо файл став меншим (ротація), починаємо читати з початку
    if (( filesize < offsets[\$logfile] )); then
      offsets[\$logfile]=0
    fi

    # Якщо є нові дані для читання
    if (( filesize > offsets[\$logfile] )); then
      # Читаємо нові рядки з файлу, починаючи з offset+1 байта
      tail -c +\$((offsets[\$logfile] + 1)) "\$logfile" >> "\$COLLECTED_LOG"
      # Оновлюємо offset
      offsets[\$logfile]=\$filesize
    fi
  done
  sleep \$SLEEP_INTERVAL
done
EOF

chmod +x "$MONITOR_SCRIPT"
chown $USER_NAME:$GROUP_NAME "$MONITOR_SCRIPT"
echo "Скрипт моніторингу створено та надано права виконання"

# Створення конфігурації logrotate для collected.log
LOGROTATE_CONF="/etc/logrotate.d/$SERVICE_NAME"

echo "Створюємо конфігурацію logrotate $LOGROTATE_CONF..."

cat > "$LOGROTATE_CONF" << EOF
$COLLECTED_LOG {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
    create 640 $USER_NAME $GROUP_NAME
}
EOF

echo "Конфігурація logrotate створена: $LOGROTATE_CONF"

echo "Готово! Тепер ви можете створити systemd-сервіс вручну з такими параметрами:"
echo "User=$USER_NAME"
echo "Group=$GROUP_NAME"
echo "ExecStart=$MONITOR_SCRIPT"
echo "WorkingDirectory=$COLLECT_DIR"
