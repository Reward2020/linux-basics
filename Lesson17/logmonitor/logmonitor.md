
### Як користуватися setup_logmonitor.sh:

1. Збережіть цей скрипт.
2. Дайте йому права на виконання:

```bash
sudo chmod +x setup_logmonitor.sh
```

3. Запустіть скрипт від root або через sudo:

```bash
sudo ./setup_logmonitor.sh
```
---

## Крок : Створення systemd Unit-файлу
Після цього у вас буде готовий користувач, директорія з правами та скрипт моніторингу. Залишиться тільки створити systemd-сервіс вручну, використовуючи вказані шляхи та користувача.
Створюємо файл `/etc/systemd/system/logmonitor.service`

```ini
[Unit]
Description=Log Monitor Service for logmonitor
After=network.target

[Service]
Type=simple
User=logmonitor
Group=adm
ExecStart=/usr/local/bin/log_monitor.sh
Restart=on-failure
RestartSec=5
WorkingDirectory=/var/logs/logmonitor
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

- `User` і `Group` — від імені кого запускаємо.
- `WorkingDirectory` — директорія з логами.
- `Restart=on-failure` — перезапуск при аварійному завершенні.
- `WantedBy=multi-user.target` — інтеграція із системним режимом, дозволяє запускати сервіс при старті системи
- Логи сервісу будуть доступні через `journalctl`.

---

## Крок : Завантаження і запуск сервісу

```bash
sudo systemctl daemon-reload
sudo systemctl enable logmonitor.service
sudo systemctl start logmonitor.service
```

Перевірка статусу:

```bash
sudo systemctl status logmonitor.service
```

Перегляд логів сервісу:

```bash
journalctl -u logmonitor.service -f
```

---

## Крок : Перевірка прав доступу

Якщо сервіс не може читати чи писати у `/var/log/logmonitor`, перевірте:

- Власника і групу директорії:

```bash
ls -ld /var/log/logmonitor
```

- Права доступу:

```bash
getfacl /var/log/logmonitor
```

- Чи належить користувач `logmonitor` до групи `adm`:

```bash
groups logmonitor
```

Якщо потрібно, змініть права або додайте користувача у потрібні групи.

---

## Додаткові рекомендації

- Якщо моніторинг логів — це Python-скрипт, вкажіть у `ExecStart` повний шлях до інтерпретатора та скрипта.
- Для більш складних налаштувань можна використовувати `EnvironmentFile` для змінних оточення.
- Для безпеки не запускайте сервіс від root, якщо це не потрібно.
- Для логування сервісу використовуйте `StandardOutput=journal` і `StandardError=journal`, щоб бачити логи через `journalctl`.
