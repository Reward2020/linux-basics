
# Показова практика: Менеджери пакетів apt, dnf, snap

## Частина 1: Архітектура та репозиторії

### Що таке пакет і репозиторій?

- Пакет — це архів із програмою та інформацією про неї (наприклад, залежності, версія).
- Репозиторій — це місце, де зберігаються пакети, зазвичай на сервері.

**Як подивитися налаштування репозиторіїв в Ubuntu:**
```bash
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/
```
**Вивід:**  
Побачите список адрес серверів, звідки система завантажує пакети.

**Перевірка цифрових підписів:**
```bash
apt-key list
```
**Вивід:**  
Список ключів, якими підписані репозиторії.

---

## Частина 2: apt та dnf — класика

### Основні команди

| Дія                  | apt (Debian/Ubuntu)                  | dnf (Fedora/RedHat)                |
|----------------------|------------------------------------|-----------------------------------|
| Оновлення списку     | `sudo apt update`                   | `sudo dnf check-update`            |
| Оновлення пакетів    | `sudo apt upgrade`                  | `sudo dnf upgrade`                 |
| Пошук пакету         | `apt search <ім'я>`                 | `dnf search <ім'я>`                |
| Інформація про пакет | `apt show <ім'я>`                   | `dnf info <ім'я>`                  |
| Встановлення         | `sudo apt install <ім'я>`           | `sudo dnf install <ім'я>`          |
| Видалення            | `sudo apt remove <ім'я>`            | `sudo dnf remove <ім'я>`           |
| Повне очищення       | `sudo apt purge <ім'я>`             | (немає прямого аналога)            |
| Перевірка встановлених пакетів | `dpkg -l` або `apt list --installed` | `dnf list installed`               |

### Приклади для Ubuntu 22.04

**Оновлення списку пакетів:**
```bash
sudo apt update
```
**Вивід:**  
Показує, які репозиторії перевіряються та чи є оновлення.

**Пошук пакету (наприклад, curl):**
```bash
apt search curl
```
**Точний збіг за назвою:**
```bash
apt search ^curl$
```
Це покаже лише пакет із назвою "curl".

**Вивід:**  
Список знайдених пакетів, наприклад:
```
curl/jammy 7.81.0-1ubuntu1.10 amd64
  command line tool for transferring data with URL syntax
```

**Інформація про пакет:**
```bash
apt show curl
```
**Вивід:**  
Детальна інформація про пакет: версія, опис, залежності.

**Встановлення пакету:**
```bash
sudo apt install curl
```
**Вивід:**  
Показує, що буде встановлено, і просить підтвердити.

**Перевірка встановлених пакетів:**
```bash
apt list --installed | grep curl
```
**Вивід:**  
Показує, чи встановлений curl.

**Видалення пакету:**
```bash
sudo apt remove curl
```
**Вивід:**  
Показує, що буде видалено.

**Повне очищення (видалення з конфігураціями):**
```bash
sudo apt purge curl
```

**Пояснення:**  
- `sudo` потрібен для змін у системі.
- `update` оновлює інформацію про пакети, а `upgrade` — самі програми.

---

## Частина 3: Snap — універсальні пакети

### Що таке Snap?

- Snap — це програма, яка містить усе необхідне для роботи (включно з бібліотеками).
- Переваги: завжди нові версії, із
оляція від системи, автоматичні оновлення.
- Недоліки: займає більше місця, може запускатися повільніше.

### Приклади для Ubuntu 22.04

**Пошук пакету (наприклад, VS Code):**
```bash
snap find code
```
**Вивід:**  
Показує список знайдених snap-пакетів, наприклад:
```
Name         Version  Publisher           Notes  Summary
code         1.86.2   snapcrafters✓       classic  Code editing. Redefined.
```

**Встановлення пакету:**
```bash
sudo snap install code --classic
```
**Вивід:**  
Показує процес завантаження та встановлення.

**Перегляд встановлених snap-пакетів:**
```bash
snap list
```
**Вивід:**  
Список усіх встановлених snap-пакетів.

**Оновлення snap-пакетів:**
```bash
sudo snap refresh
```
**Вивід:**  
Показує, які пакети оновлено.

**Відкат версії snap-пакету:**
```bash
sudo snap revert code
```
**Вивід:**  
Повертає попередню версію пакету.

---

## Частина 4: DevOps сценарій (практичне застосування)

- Рівні використання пакетів:

| Рівень           | Приклади              | Менеджер               | Коментар                          |
|------------------|----------------------|-----------------------|----------------------------------|
| Базова ОС        | ядро, ssh, systemd   | apt/dnf               | Для основних програм використовують класичні менеджери, snap не підходить |
| Серверні сервіси | nginx, postgresql    | apt/dnf + офіційні репозиторії | Баланс між стабільністю і новими версіями |
| Інструменти      | VS Code, kubectl     | snap                  | Швидке оновлення, ізоляція      |

**Встановлення Docker через офіційний репозиторій (Ubuntu):**

**Для старіших версій** [убунти](https://docs.docker.com/engine/install/ubuntu/#install-from-a-package) 
```bash
sudo apt update
sudo apt install \
    ca-certificates \
    curl \
    gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
```
**Для новіших версій** [убунти](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) 
```bash
sudo apt update \
sudo apt install ca-certificates curl \
sudo install -m 0755 -d /etc/apt/keyrings \
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
sudo chmod a+r /etc/apt/keyrings/docker.asc
```
**Додати репозиторій до ресурсів** `apt`
```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```
**Вивід:**  
Показує процес додавання репозиторію та встановлення Docker.

**Встановлення VS Code через snap:**
```bash
sudo snap install code --classic
```

---

## Частина 5: Найкращі практики

- Використовуйте `--dry-run` або `-s` для перевірки, що зміниться:
```bash
sudo apt-get -s upgrade
```
- Періодично перевіряйте встановлені програми:
```bash
apt list --installed
snap list
```
- Не додавайте зайві сторонні репозиторії без потреби.
- Нові програми тестуйте в ізольованому середовищі (snap вже ізольований).
- Не використовуйте snap для важливих системних сервісів.

---
