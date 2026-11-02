# Материалы для App Store

Всё, что вносится в App Store Connect для Splitway 1.0 ([release-steps.md](../05-tasks/release-steps.md), шаги 5–8). Тексты и ответы лежат здесь, страницы политики и поддержки — в [Site](../../Site), скриншоты — в `build/app-store/screenshots` (каталог вне git).

| Что | Где | Шаг плана |
|---|---|---|
| Сборки iOS и macOS | `Scripts/release.sh <версия>` | 5 |
| Политика конфиденциальности и поддержка, русский и английский | [Site](../../Site) | 7 |
| Название, подзаголовок, рекламный текст, ключевые слова, описания | [listing.en.md](listing.en.md), [listing.ru.md](listing.ru.md) | 8 |
| Категория, возрастной рейтинг, App Privacy, экспорт шифрования | [questionnaires.md](questionnaires.md) | 5, 8 |
| Заметки для ревьюера | [review-notes.md](review-notes.md) | 8 |
| Скриншоты iPhone, iPad и Mac | `build/app-store/screenshots` | 8 |

## Что заполнить перед публикацией

- `SUPPORT_EMAIL` в `Site/en/support.html` и `Site/ru/support.html` — адрес почты поддержки.
- `[TEST CONFIGURATION]` в [review-notes.md](review-notes.md) — ссылка на конфиг для ревьюера или файл во вложении.
- Copyright в [questionnaires.md](questionnaires.md) — название организации после перевода аккаунта (D-03).
- Адрес сайта в ссылках на политику и поддержку — когда страницы будут опубликованы.

## Сборка выпуска

`Scripts/release.sh 1.0` собирает движок, генерирует проект и архивирует оба приложения в Release с версией `1.0` и номером сборки, равным числу коммитов (`git rev-list --count HEAD`): он растёт с каждым коммитом в `master`, а замена системного расширения и имя Mach-сервиса опираются на него. Скрипт требует чистую рабочую копию.

- **Без флагов** архивы ложатся в `~/Library/Developer/Xcode/Archives/<дата>`, и Organizer Xcode показывает их как «Splitway iOS 1.0 (N)» и «Splitway macOS 1.0 (N)». Дальше — Distribute App → App Store Connect → Upload.
- **С `--upload`** скрипт экспортирует каждый архив способом `app-store-connect` и загружает его ключом App Store Connect API. Нужны переменные `SPLITWAY_ASC_KEY_ID` и `SPLITWAY_ASC_ISSUER_ID`. Файл ключа по умолчанию лежит в `~/.appstoreconnect/private_keys/AuthKey_<Key ID>.p8`, другой путь задаёт `SPLITWAY_ASC_KEY_FILE`.

Проверено 2026-11-02 пробной архивацией: iOS 1.0 и macOS 1.0 собрались. Версия и номер сборки одинаковы у приложений и всех расширений, у Mac — универсальная сборка (arm64 и x86_64) с песочницей, правами Network Extension без суффикса Developer ID и Hardened Runtime. Экспорт и загрузка ещё не проверялись: для них нужны запись в App Store Connect и сертификаты владельца (шаги 3–4).

## Скриншоты

| Устройство | Размер | Откуда |
|---|---|---|
| iPhone 6,9″ | 1320 × 2868 | `Scripts/capture-materials.sh` ([localization.md](../localization.md)) |
| iPad 13″ | 2064 × 2752 | то же |
| Mac | 2560 × 1600 | окна Splitway из тестовой ВМ на синем фоне |

На каждое устройство и язык — `build/app-store/screenshots/<устройство>/<en|ru>`. Демо-туннели — со случайными ключами и адресами `*.example.net`.

Mac-снимки сняты 2026-11-02 в тестовой ВМ со сборкой в песочнице. Окно (около 960 × 575 точек) уложено на холст 2560 × 1600 — один из размеров, которые принимает Mac App Store, — с заголовком и подзаголовком над ним:

| Файл | Экран | English | Русский |
|---|---|---|---|
| `01-main` | главное окно: «Прага» с выбранными Safari и Терминалом | Only the apps you choose use the tunnel / Everything else stays on your regular connection. | Через туннель — только выбранные приложения / Всё остальное идёт обычным путём. |
| `02-apps` | лист выбора приложений с фильтром «Выбранные» | Pick apps and command-line tools / Commands run in a selected Terminal go through the tunnel too. | Выбирайте приложения и утилиты / Команды в выбранном Терминале тоже идут через туннель. |
| `03-routing` | раздел «Маршрутизация» редактора с блокировкой при недоступном туннеле | Blocked, not exposed, if the tunnel drops / Chosen apps wait for the tunnel instead of going direct. | Туннель упал — трафик не утечёт / Выбранные приложения ждут туннель, а не уходят напрямую. |

## Решения

- Название в App Store — Splitway Tunnel (D-43): «Splitway» занято чужой записью. На устройстве приложение называется Splitway, а слово «tunnel» из названия не повторяется в ключевых словах, потому что App Store ищет и по названию.
- Названия чужих сервисов и приложений в текстах не упоминаются (правило 2.3.7): каталог описан словами «мессенджеры, соцсети, видео, музыка и сервисы ИИ».
- «WireGuard» есть в подзаголовке и описании, потому что приложение совместимо с этим протоколом, а в конце описания стоит пометка о товарном знаке. В ключевых словах его нет.
- Описания iOS и macOS разные: на iPhone и iPad выбираются сервисы, на Mac — приложения.
