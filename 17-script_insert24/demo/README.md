# Підготовка до виконання скрипта
## Хвилика уваги


Дякую за уточнення!  
**Цей скрипт НЕ буде працювати, якщо база даних не PostgreSQL.** Ось чому:

1. **Використовується psql**  
   Скрипт використовує команду psql — це клієнт саме для PostgreSQL. Якщо на системі встановлена інша СУБД (наприклад, MySQL, SQLite, MariaDB), команда psql або не буде знайдена, або не зможе підключитися до такої бази.

2. **Синтаксис SQL**  
   Навіть якщо інша СУБД має клієнт з такою ж назвою (що малоймовірно), синтаксис команд INSERT INTO ... VALUES ... може відрізнятися.

3. **Параметри підключення**  
   Параметри -U (user), -d (database), -c (command) — це специфіка psql. В інших СУБД (наприклад, у MySQL це буде mysql -u user -p dbname -e "SQL") ці параметри інші.

Детальна інформація що потрібно змінити для сумісності з іншими [Базами Даних](#потрібно-змінити-bash-скрипті-для-підтримки-інших-популярних-субд) 
---



# Встановлення PostgreSQL у Ubuntu 
використовуйте такі команди:

```bash
# Оновіть список пакетів
sudo apt update

# Встановіть PostgreSQL та утиліти клієнта
sudo apt install -y postgresql postgresql-contrib

# Перевірте статус служби PostgreSQL
sudo systemctl status postgresql

# (Опціонально) Увімкніть автозапуск при старті системи
sudo systemctl enable postgresql
```

**Після встановлення**  
- Користувач postgres створюється автоматично.
- Для входу в psql:
  ```bash
  sudo -u postgres psql
  ```

Щоб **створити власного користувача** та власну базу даних у PostgreSQL, виконайте такі кроки у psql:

1. **Створіть користувача (роль):**
```sql
CREATE USER myuser WITH PASSWORD 'mypassword';
```
Замініть myuser і mypassword на бажані ім’я користувача та пароль.

2. **Створіть базу даних:**
```sql
CREATE DATABASE mydb OWNER myuser;
```
mydb — це ім’я нової бази даних, myuser — власник (щойно створений користувач).

3. **(Опціонально) Надати додаткові права:**
Якщо потрібно, щоб користувач міг створювати таблиці, схеми тощо:
```sql
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;
```

**Після цього ви зможете підключатися до нової бази під новим користувачем:**
```bash
psql -U myuser -d mydb
```

**Пояснення:**
- Роль myuser не є суперкористувачем і не має глобальних прав, але вона є власником бази mydb і має всі права в цій базі.
- Доступ до бази визначається не атрибутами ролі, а саме правами на базу (що ви вже надали через GRANT ALL PRIVILEGES).

**Як перевірити доступ:**
1. Вийдіть з psql (якщо ви під postgres):
   ```
   \q
   ```
2. Підключіться під користувачем myuser:
   ```
   psql -U myuser -d mydb
   ```
   Якщо пароль не заданий, створіть його:
   ```
   ALTER USER myuser WITH PASSWORD 'yourpassword';
   ```
   (Виконайте цю команду під postgres.)

3. Після підключення спробуйте створити таблицю:
   ```sql
   CREATE TABLE test_table (id serial PRIMARY KEY, name text);
   ```
   Якщо команда виконується — все працює.

# Структура таблиці (створіть у psql):
```sql
CREATE TABLE users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  email text
);
```
## Як протестувати
- Створіть власний файл users.txt з іменами або можете використати вкладений
- Запустіть скрипт `insert_users.sh`
```bash
./insert_users.sh users.txt
```
- Перевірте в базі `SELECT * FROM users;`


Щоб очистити таблицю users від усіх імен (видалити всі записи), використайте одну з наступних SQL-команд у psql:

1. **Видалити всі рядки, залишивши структуру таблиці:**
```sql
TRUNCATE TABLE users;
```
або
```sql
DELETE FROM users;
```

- `TRUNCATE` швидше і скидає лічильник id (serial) на початкове значення.
- `DELETE` просто видаляє всі записи, але лічильник id продовжує рахувати далі.



# Потрібно змінити Bash-скрипті для підтримки інших популярних СУБД

---

## 1. **MySQL/MariaDB**

### Основні зміни:
- **Клієнт:** замість psql використовується mysql.
- **Параметри:**  
  - `-u` — користувач  
  - `-p` — пароль (запитує або можна додати без пробілу: -pPASSWORD)  
  - `-D` — база даних  
  - `-e` — виконати SQL-команду

### Приклад вставки:
```bash
mysql -u myuser -p -D mydb -e "INSERT INTO users (username, email) VALUES ('$username', '$email');"
```
> Якщо email порожній, можна вставити NULL:
```bash
mysql -u myuser -p -D mydb -e "INSERT INTO users (username, email) VALUES ('$username', NULL);"
```

### Весь цикл:
```bash
while IFS=, read -r username email; do
  if [[ -z "$username" ]]; then
    echo "Empty username, skipping"
    continue
  fi
  if [[ -z "$email" ]]; then
    mysql -u myuser -p -D mydb -e "INSERT INTO users (username, email) VALUES ('$username', NULL);" \
      && echo "Inserted: $username (no email)" \
      || echo "Failed to insert: $username"
  else
    mysql -u myuser -p -D mydb -e "INSERT INTO users (username, email) VALUES ('$username', '$email');" \
      && echo "Inserted: $username, $email" \
      || echo "Failed to insert: $username"
  fi
done < "$USER_FILE"
```
> **Зверніть увагу:**  
> - MySQL за замовчуванням запитає пароль. Для автоматизації можна використати файл з паролем або змінну середовища.

---

## 2. **SQLite**

### Основні зміни:
- **Клієнт:** sqlite3
- **Параметри:**  
  - Ім'я файлу бази даних  
  - SQL-команда в лапках

### Приклад вставки:
```bash
sqlite3 mydb.sqlite "INSERT INTO users (username, email) VALUES ('$username', '$email');"
```
> Якщо email порожній:
```bash
sqlite3 mydb.sqlite "INSERT INTO users (username, email) VALUES ('$username', NULL);"
```

---

## 3. **Oracle (sqlplus)**

### Основні зміни:
- **Клієнт:** sqlplus
- **Параметри:**  
  - Користувач/пароль@сервіс  
  - SQL-команда через echo або heredoc

### Приклад вставки:
```bash
echo "INSERT INTO users (username, email) VALUES ('$username', '$email');" | sqlplus myuser/password@mydb
```

---

## 4. **Універсальний підхід (псевдокод):**

```bash
DB_TYPE="postgres" # або "mysql", "sqlite"

case "$DB_TYPE" in
  postgres)
    # psql команда
    ;;
  mysql)
    # mysql команда
    ;;
  sqlite)
    # sqlite3 команда
    ;;
esac
```

---

## **Важливі відмінності:**
- **Клієнт та параметри підключення різні для кожної СУБД.**
- **Синтаксис SQL INSERT схожий, але можуть бути нюанси з NULL, лапками, escape-символами.**
- **Для MySQL/MariaDB та Oracle потрібно окремо обробляти пароль.**
- **Для SQLite база — це файл, а не сервер.**
