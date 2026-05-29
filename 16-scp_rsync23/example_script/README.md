## Загальний опис

Цей скрипт динамічно генерує частину конфігурації для GitLab CI/CD у форматі YAML (`generated-config.yml`), яка автоматизує процеси роботи з Terraform — інструментом для управління інфраструктурою як кодом (IaC).

В результаті виконання скрипта у файл `generated-config.yml` додаються декілька GitLab CI job-ів (завдань), що послідовно виконують:

- Ініціалізацію Terraform (terraform init)
- Валідацію конфігурації Terraform (terraform validate, terraform fmt)
- Планування змін (terraform plan)
- Сповіщення у Slack про результати планування (за певних умов)
- Застосування змін (terraform apply) — вручну

---

## Аргументи скрипту

Скрипт приймає 5 позиційних аргументів:

| Аргумент  | Опис                                                                                  |
|-----------|---------------------------------------------------------------------------------------|
| `TF_ROOT` | Шлях до кореневої папки з Terraform кодом. Якщо `"./"`, вважається, що код у корені. |
| `TAGS`    | Теги GitLab Runner, які визначають, на яких раннерах запускати job-и.                  |
| `ENV`     | Назва середовища (наприклад, `dev`, `staging`, `production`).                         |
| `TIER`    | Рівень середовища (наприклад, `production`, `development`).                           |
| `PHI_ENV` | Ідентифікатор середовища для формування імені Docker-образів (наприклад, `dev`).      |

---

## Детальний опис логіки скрипта

Розглянемо поетапно цей фрагмент скрипта:

```bash
TF_ROOT="$1"
TAGS=$2
ENV=$3
TIER=$4
PHI_ENV=$5

if [ "$TF_ROOT" == "./" ]
  then TF_CODE_ROOT="in_root"
  else TF_CODE_ROOT=$TF_ROOT
fi
```

---

## Пояснення по кроках

1. **Присвоєння аргументів скрипту змінним**

   - `TF_ROOT="$1"` — перший позиційний аргумент скрипта записується у змінну `TF_ROOT`. Це шлях до кореневої папки з Terraform кодом.
   - `TAGS=$2` — другий аргумент — теги GitLab Runner.
   - `ENV=$3` — третій аргумент — назва середовища (наприклад, `dev`, `prod`).
   - `TIER=$4` — четвертий аргумент — рівень середовища (наприклад, `production`, `development`).
   - `PHI_ENV=$5` — п’ятий аргумент — додатковий параметр, який використовується для формування імені Docker-образів (може бути, наприклад, `dev`).

2. **Умова для визначення змінної `TF_CODE_ROOT`**

   ```bash
   if [ "$TF_ROOT" == "./" ]
     then TF_CODE_ROOT="in_root"
     else TF_CODE_ROOT=$TF_ROOT
   fi
   ```

   - Якщо шлях до Terraform коду вказаний як `"./"` (поточна директорія), то для унікальності імен job-ів у CI використовується значення `in_root`.
   - Інакше `TF_CODE_ROOT` приймає значення шляху `TF_ROOT` без змін.

   Це потрібно, щоб уникнути проблем з іменами job-ів у випадку, коли код лежить безпосередньо в корені репозиторію.

---

## Порядок передачі аргументів при виклику скрипта

Аргументи потрібно передавати у такому порядку:

1. **`TF_ROOT`** — шлях до каталогу з Terraform кодом (наприклад, `"./"`, `"terraform"`, `"modules/network"`).
2. **`TAGS`** — теги GitLab Runner (наприклад, `"docker,linux"`).
3. **`ENV`** — назва середовища (наприклад, `"dev"`, `"staging"`, `"prod"`).
4. **`TIER`** — рівень середовища (наприклад, `"production"`, `"development"`).
5. **`PHI_ENV`** — додатковий параметр для формування імені Docker-образів (наприклад, `"dev"`).


## GitLab CI/CD pipeline

Як працює цей фрагмент скрипту, який генерує частину GitLab CI/CD pipeline у форматі YAML, але на прикладі **`tf_init_$TF_CODE_ROOT`** job-а — бо всі job-и дуже схожі по структурі, відрізняються лише командами у `script` та деякими додатковими параметрами.

Цей фрагмент:

```bash
cat <<EOF >> generated-config.yml

tf_init_$TF_CODE_ROOT:
  stage: terraform_init
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
    entrypoint:
     - '/usr/bin/env'
     - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  script:
    - echo $TF_ROOT
    - cd $TF_ROOT
    - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com  #gitleaks:allow
    - terraform init
  tags: $TAGS

EOF
```

означає:

- Через `cat <<EOF >> generated-config.yml` ми **додаємо (append)** цей текст у файл `generated-config.yml`.  
- У цьому тексті описується job для GitLab CI/CD з ім’ям `tf_init_$TF_CODE_ROOT`, де `$TF_CODE_ROOT` — це змінна, яку ми визначили раніше (наприклад, `in_root` або шлях до папки).
- В результаті у файлі `generated-config.yml` формується частина pipeline, яку можна буде підключити у `.gitlab-ci.yml`.

---

## Пояснення ключових частин job-а `tf_init_$TF_CODE_ROOT`

### Ім'я job-а

```yaml
tf_init_$TF_CODE_ROOT:
```

- Ім’я job-а формується динамічно, наприклад: `tf_init_in_root` або `tf_init_terraform`.
- Це потрібно, щоб мати унікальні job-и для кожного Terraform каталогу.

---

### `stage`

```yaml
stage: terraform_init
```

- Вказує, що цей job виконується на стадії `terraform_init`.
- Стадії визначають порядок виконання job-ів у pipeline.

---

### `image`

```yaml
image:
  name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/builder-terraform:stable
  entrypoint:
   - '/usr/bin/env'
   - 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
```

- Вказує Docker-образ, який буде використаний для виконання команд у job-і.
- Образ береться з приватного реєстру (`us-docker.pkg.dev`), де `<PROJECT>`, `$PHI_ENV`, `<REGISTRY>` — змінні, що підставляються.
- `entrypoint` задає команду запуску контейнера, тут використовується `/usr/bin/env` з певним `PATH`, щоб забезпечити коректне оточення.

---

### `script`

```yaml
script:
  - echo $TF_ROOT
  - cd $TF_ROOT
  - git config --global url."https://"\$DEPLOY_TOKEN_NAME":"\$DEPLOY_TOKEN"@gitlab.com".insteadOf https://gitlab.com  #gitleaks:allow
  - terraform init
```

- Це послідовність команд, які виконаються у контейнері.
- `echo $TF_ROOT` — виводить значення змінної `TF_ROOT` для налагодження.
- `cd $TF_ROOT` — переходимо у папку з Terraform кодом.
- `git config --global url."https://$DEPLOY_TOKEN_NAME:$DEPLOY_TOKEN@gitlab.com".insteadOf https://gitlab.com` — налаштовує git на використання токенів для доступу до приватних репозиторіїв GitLab (захищено від витоку токенів за допомогою `#gitleaks:allow`).
- `terraform init` — ініціалізує Terraform (завантажує провайдери, модулі тощо).

---

### `tags`

```yaml
tags: $TAGS
```

- Вказує теги GitLab Runner, на яких може виконуватися цей job.
- Значення `$TAGS` передається у скрипт як аргумент, наприклад: `"docker,linux"`.

---

## Як це працює у контексті інших job-ів?

Інші job-и (`tf_validate_$TF_CODE_ROOT`, `tf_plan_$TF_CODE_ROOT`) мають схожу структуру:

- Вони використовують той же Docker-образ.
- Переходять у ту ж папку `$TF_ROOT`.
- Виконують додаткові команди Terraform (`terraform fmt`, `terraform validate`, `terraform plan`).
- Вказують залежності через `needs`, щоб job-и запускалися послідовно.
- Зберігають артефакти (наприклад, план Terraform).

---

# Розбір job-а `slack_notification_$TF_CODE_ROOT`

```yaml
slack_notification_$TF_CODE_ROOT:
  stage: slack_notification
  image:
    name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/gcloud:latest
  script:
    - |
      # скрипт тут
  needs:
    - job: tf_plan_$TF_CODE_ROOT
  rules:
    - if: '"$CI_COMMIT_BRANCH" == "main" && "$TIER" == "production"'
  tags: $TAGS
```

---

### Ім’я job-а

- `slack_notification_$TF_CODE_ROOT` — ім’я job-а динамічне, як і в інших job-ах, де `$TF_CODE_ROOT` — змінна, що вказує контекст (наприклад, папку з Terraform кодом).
- Це дозволяє мати окремі нотифікації для різних частин інфраструктури.

---

### `stage`

```yaml
stage: slack_notification
```

- Job виконується на стадії `slack_notification`, яка йде після стадії `terraform_plan`.
- Це означає, що повідомлення у Slack надсилаються після того, як Terraform план готовий.

---

### `image`

```yaml
image:
  name: us-docker.pkg.dev/<PROJECT>-$PHI_ENV-<REGISTRY>/gcloud:latest
```

- Використовується Docker-образ з Google Cloud SDK (`gcloud`), який містить утиліти `curl`, `jq` та інші потрібні інструменти.
- Це зручно для роботи з API та обробки JSON.

---

#### Покроковий розбір скрипту slack_notification:

1. **Перевірка, чи є середовище захищеним**

```bash
API_URL="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/protected_environments"
response=$(curl --silent --header "PRIVATE-TOKEN: $BOT_TOKEN" "${API_URL}")
is_protected=$(echo "$response" | jq --arg env "${ENV%/}" 'map(.name) | index($env) != null')
```

- Отримуємо список захищених середовищ проекту через GitLab API.
- Перевіряємо, чи є поточне середовище (`$ENV`, без останнього слешу `${ENV%/}`) у списку захищених.
- Змінна `is_protected` буде `"true"` або `"false"`.

2. **Якщо середовище не захищене — вихід**

```bash
if [[ "$is_protected" != "true" ]]; then
  echo "The environment "${ENV%/}" is NOT protected."
  exit 0
```

- Якщо середовище не захищене, job завершується без помилки (`exit 0`), повідомлення не надсилається.

3. **Якщо середовище захищене — готуємо повідомлення**

```bash
else
  echo "The environment "${ENV%/}" IS protected."
  PLAN_FILE_URL=$(cat plan_job_url.txt)
```

- Виводимо підтвердження захищеності.
- Зчитуємо URL плану Terraform з файлу `plan_job_url.txt`.

4. **Отримуємо ID середовища у GitLab**

```bash
ENV_ID=$(curl --header "PRIVATE-TOKEN: $BOT_TOKEN" "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/environments?per_page=100" | jq '(.[] | select(.name == "'$ENV'") | .id)' )
```

- Запитуємо список середовищ і фільтруємо по імені `$ENV`, щоб отримати унікальний ID.

5. **Формуємо посилання на сторінку середовища**

```bash
APPROVAL_LINK_URL=($CI_PROJECT_URL/-/environments/$ENV_ID)
```

- Посилання, де можна переглянути середовище у GitLab.

6. **Отримуємо ID користувачів, які мають дозвіл на деплой**

```bash
USER_IDS=$(curl --header "PRIVATE-TOKEN: $BOT_TOKEN" "https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/protected_environments/$(echo $ENV | sed 's/\//%2F/g')" | jq --raw-output '.deploy_access_levels[].user_id')
```

- Запитуємо список користувачів, які мають права на деплой у це середовище.

7. **Формуємо email цих користувачів**

```bash
EMAILS=$(for i in $USER_IDS; do curl --header "PRIVATE-TOKEN: $BOT_TOKEN" "https://gitlab.com/api/v4/users/$i" | ( jq --raw-output '.name') | tr ' ' '.' | awk '{print $1"@medecision.com"}'; done)
```

- Для кожного користувача отримуємо ім’я, перетворюємо у формат email (наприклад, `John Doe` → `John.Doe@medecision.com`).
- Тут зроблено припущення про домен `@medecision.com`.

8. **Отримуємо Slack ID користувачів за email**

```bash
USERS=$(echo $(for i in ${EMAILS[@]}; do curl -F email=$i https://slack.com/api/users.lookupByEmail -H "Authorization: Bearer $SLACK_TOKEN" | jq --raw-output '.user.id'  | sed "s/^/<@/;s/$/>/" ; done))
```

- Для кожного email робимо запит до Slack API, щоб отримати Slack User ID.
- Форматуємо у вигляді `<@USERID>`, щоб згадати користувача у повідомленні.

9. **Формуємо список Slack ID для відкриття приватного каналу**

```bash
SLACK_IDS1=$(echo $(for i in ${EMAILS[@]}; do curl -F email=$i https://slack.com/api/users.lookupByEmail -H "Authorization: Bearer $SLACK_TOKEN" | jq --raw-output '.user.id'; done) | tr ' ' ',')
SLACK_IDS=($SLACK_IDS1,U02H6PLMXSA)
```

- Отримуємо ті ж Slack ID у форматі через кому.
- Додаємо додатковий Slack ID `U02H6PLMXSA` (можливо, це ID бота або адміністратора).

10. **Відкриваємо приватний Slack канал з цими користувачами**

```bash
CHANNEL_ID=$(curl -X POST -F users="$SLACK_IDS" https://slack.com/api/conversations.open -H "Authorization: Bearer $SLACK_TOKEN" | jq --raw-output '.channel.id')
```

- Створюємо (або відкриваємо існуючий) канал з цими користувачами.
- Отримуємо ID каналу.

11. **Редагуємо шаблон повідомлення `slack.json`**

```bash
sed -i "s/CHANNEL_ID/$CHANNEL_ID/g" slack.json
sed -i "s/USERS/$USERS/g" slack.json
sed -i "s%PLAN_FILE_URL%$PLAN_FILE_URL%g" slack.json
sed -i "s/CI_PROJECT_TITLE/$CI_PROJECT_TITLE/g" slack.json
sed -i "s%ENVIRONMENT_NAME%$ENV%g" slack.json
sed -i "s%APPROVAL_LINK_URL%$APPROVAL_LINK_URL%g" slack.json
```

- Замінюємо у JSON-шаблоні повідомлення плейсхолдери на реальні значення.

12. **Надсилаємо повідомлення у Slack**

```bash
curl -H "Content-Type: application/json; charset=utf-8" --data  @slack.json -H "Authorization: Bearer $SLACK_TOKEN" -X POST https://slack.com/api/chat.postMessage
```

- Відправляємо сформоване повідомлення через Slack API.

---

### `needs`

```yaml
needs:
  - job: tf_plan_$TF_CODE_ROOT
```

- Цей job залежить від успішного виконання job-а `tf_plan_$TF_CODE_ROOT`.
- Тобто повідомлення надсилається лише після того, як план Terraform сформовано.

---

### `rules`

```yaml
rules:
  - if: '"$CI_COMMIT_BRANCH" == "main" && "$TIER" == "production"'
```

- Job запускається **тільки якщо:**
  - Гілка коміту — `main`.
  - Змінна `$TIER` дорівнює `production`.
- Це обмежує відправку повідомлень лише для основної (продакшн) гілки.

---

### `tags`

```yaml
tags: $TAGS
```

- Вказує теги GitLab Runner, на яких має запускатися цей job.

---

# Підсумок

- Job `slack_notification_$TF_CODE_ROOT` відповідає за **перевірку, чи є середовище захищеним**, і якщо так — надсилає **сповіщення у Slack** користувачам, які мають права на деплой.
- Для цього він:
  - Використовує GitLab API для отримання інформації про середовище та користувачів.
  - Формує email та Slack ID користувачів.
  - Відкриває Slack канал для цих користувачів.
  - Формує повідомлення з посиланнями на Terraform план і середовище.
  - Відправляє повідомлення через Slack API.
- Job запускається лише для продакшн-гілки `main` і після успішного створення Terraform плану.
- Фрагмент **GitLab CI/CD генерує конфігурацію, що ініціалізує Terraform у конкретній папці.**
- Ім’я job-и динамічне, щоб можна було запускати pipeline для різних частин Terraform коду.
- Використовується Docker-образ із Terraform.
- Налаштовується git для приватного доступу.
- Виконується `terraform init, terraform validate, terraform plan, terraform apply`.
- Job запускається на GitLab Runner з тегами `$TAGS`.

## Для чого це потрібно?

- **Автоматизація:** Автоматично генерує CI/CD job-и для роботи з Terraform, що дозволяє стандартизувати процеси.
- **Безпека:** Використовує токени для доступу до приватних репозиторіїв і API, а також перевіряє захищеність середовища перед відправкою повідомлень.
- **Контроль:** Забезпечує поетапну перевірку та планування змін, а застосування — лише вручну після підтвердження.
- **Сповіщення:** Інформує відповідальних у Slack про необхідність перевірки та затвердження змін.
- **Гнучкість:** Параметризований шлях до Terraform коду, середовище, теги і рівень, що дозволяє використовувати один скрипт для різних проектів і середовищ.

---
