# Материалы для App Store

Всё, что вносится в App Store Connect для Splitway 1.0 ([release-steps.md](../05-tasks/release-steps.md), шаги 5–8). Тексты и ответы лежат здесь, страницы политики и поддержки — в [Site](../../Site), скриншоты — в `build/app-store/screenshots`, обложка и картинки для поиска — в `build/app-store/creative` (оба каталога вне git).

| Что | Где | Шаг плана |
|---|---|---|
| Сборки iOS и macOS | `Scripts/release.sh <версия>` | 5 |
| Политика конфиденциальности и поддержка, русский и английский | [Site](../../Site) | 7 |
| Название, подзаголовок, рекламный текст, ключевые слова, описания | [listing.en.md](listing.en.md), [listing.ru.md](listing.ru.md) | 8 |
| Категория, возрастной рейтинг, App Privacy, экспорт шифрования | [questionnaires.md](questionnaires.md) | 5, 8 |
| Заметки для ревьюера | [review-notes.md](review-notes.md) | 8 |
| Скриншоты iPhone, iPad и Mac | `build/app-store/screenshots` | 8 |
| Обложка и картинки для поиска iOS 27 | `build/app-store/creative` | 8 |

## Что заполнить перед публикацией

- Адрес почты поддержки: пока связь — через GitHub Issues сайта, адрес добавится на обе страницы поддержки.
- `[TEST CONFIGURATION]` в [review-notes.md](review-notes.md) — ссылка на конфиг для ревьюера или файл во вложении.
- Copyright в [questionnaires.md](questionnaires.md) — название организации после перевода аккаунта (D-03).

## Сайт

Страницы опубликованы 2026-11-02 через GitHub Pages из публичного репозитория [facelessdiplomat/facelessdiplomat.github.io](https://github.com/facelessdiplomat/facelessdiplomat.github.io):

- поддержка — https://facelessdiplomat.github.io/en/support.html и https://facelessdiplomat.github.io/ru/support.html;
- политика конфиденциальности — https://facelessdiplomat.github.io/en/privacy.html и https://facelessdiplomat.github.io/ru/privacy.html.

Источник страниц — папка [Site](../../Site) этого репозитория. Чтобы обновить сайт, скопируйте её содержимое в репозиторий сайта (там же лежит пустой `.nojekyll`) и отправьте в `main`: GitHub Pages пересоберёт сайт за минуту. Политика собирается из `docs/privacy-policy.*.md`: при её изменении обновите и страницы. Пока нет почты поддержки, связь — через Issues репозитория сайта, и страница просит не выкладывать туда конфигурации, ключи и отчёты.

## Сборка выпуска

`Scripts/release.sh 1.0` собирает движок, генерирует проект и архивирует оба приложения в Release с версией `1.0` и номером сборки, равным числу коммитов (`git rev-list --count HEAD`): он растёт с каждым коммитом в `master`, а замена системного расширения и имя Mach-сервиса опираются на него. Скрипт требует чистую рабочую копию.

- **Без флагов** архивы ложатся в `~/Library/Developer/Xcode/Archives/<дата>`, и Organizer Xcode показывает их как «Splitway iOS 1.0 (N)» и «Splitway macOS 1.0 (N)». Дальше — Distribute App → App Store Connect → Upload.
- **С `--upload`** скрипт экспортирует каждый архив способом `app-store-connect` и загружает его ключом App Store Connect API. Нужны переменные `SPLITWAY_ASC_KEY_ID` и `SPLITWAY_ASC_ISSUER_ID`. Файл ключа по умолчанию лежит в `~/.appstoreconnect/private_keys/AuthKey_<Key ID>.p8`, другой путь задаёт `SPLITWAY_ASC_KEY_FILE`.

Проверено 2026-11-02 пробной архивацией: iOS 1.0 и macOS 1.0 собрались. Версия и номер сборки одинаковы у приложений и всех расширений, у Mac — универсальная сборка (arm64 и x86_64) с песочницей, правами Network Extension без суффикса Developer ID и Hardened Runtime. Экспорт и загрузка ещё не проверялись: для них нужны запись в App Store Connect и сертификаты владельца (шаги 3–4).

## Скриншоты

| Вкладка App Store Connect | Размер | Папка | Нужна ли |
|---|---|---|---|
| iPhone with Dynamic Island (medium display) | 1206 × 2622 | `iphone-medium` | обязательна |
| iPhone with Dynamic Island (large display) | 1320 × 2868 | `iphone-large` | закрывает требование к большому экрану iPhone: без неё App Store Connect попросит снимки iPhone with Face ID (large display), 1284 × 2778 |
| iPhone Duo | внешний экран 1398 × 2034, внутренний 2007 × 2853 | нет | необязательна до апреля 2027 года, потом понадобится сборкам на SDK iOS 27.1 и новее |
| iPad 13″ | 2064 × 2752 | `ipad` | обязательна: приложение работает на iPad |
| Mac | 2560 × 1600 | `mac` | обязательна для macOS |

На каждое устройство и язык — `build/app-store/screenshots/<папка>/<en|ru>`. Снимки iPhone и iPad собраны из экранов `Scripts/capture-materials.sh` ([localization.md](../localization.md)) на синем фоне с подписью, Mac — из окон Splitway в тестовой ВМ. Демо-туннели — со случайными ключами и адресами `*.example.net`.

iPhone и iPad (2026-11-03) собраны из экранов M7-07: интерфейс iOS с тех пор не менялся. Оба набора iPhone собраны из одних и тех же снимков 6,9″, только на холстах разного размера. Экран занимает одинаковое место на всех слайдах, а под заголовок оставлено до двух строк. На iPhone четыре слайда, на iPad три: на планшете список туннелей и экран туннеля видны одновременно, поэтому отдельный слайд со списком повторял бы второй.

| Файл | Экран | English | Русский |
|---|---|---|---|
| `01-services` | выбор сервисов | Choose which services use the tunnel / Everything else stays on your regular connection. | Выберите сервисы для туннеля / Всё остальное идёт обычным путём. |
| `02-details` | туннель «Прага» с его сервисами | See what goes through the tunnel / Each tunnel keeps its own routing and services. | Видно, что идёт через туннель / У каждого туннеля свой режим и свои сервисы. |
| `03-tunnels` (только iPhone) | список туннелей | All your WireGuard tunnels in one place / Import a file, paste a configuration or scan a QR code. | Все туннели WireGuard в одном месте / Импорт из файла, буфера обмена или по QR-коду. |
| `04-editor` на iPhone, `03-editor` на iPad | редактор | Edit tunnels right on your iPhone (iPad) / Keys, addresses, DNS and routing. | Правьте туннели прямо на iPhone (iPad) / Ключи, адреса, DNS и маршрутизация. |

Mac-снимки сняты 2026-11-02 в тестовой ВМ со сборкой в песочнице. Окно (около 960 × 575 точек) уложено на холст 2560 × 1600 — один из размеров, которые принимает Mac App Store, — с заголовком и подзаголовком над ним:

| Файл | Экран | English | Русский |
|---|---|---|---|
| `01-main` | главное окно: «Прага» с выбранными Safari и Терминалом | Only the apps you choose use the tunnel / Everything else stays on your regular connection. | Через туннель — только выбранные приложения / Всё остальное идёт обычным путём. |
| `02-apps` | лист выбора приложений с фильтром «Выбранные» | Pick apps and command-line tools / Commands run in a selected Terminal go through the tunnel too. | Выбирайте приложения и утилиты / Команды в выбранном Терминале тоже идут через туннель. |
| `03-routing` | раздел «Маршрутизация» редактора с блокировкой при недоступном туннеле | Blocked, not exposed, if the tunnel drops / Chosen apps wait for the tunnel instead of going direct. | Туннель упал — трафик не утечёт / Выбранные приложения ждут туннель, а не уходят напрямую. |

## Обложка и картинки для поиска

С iOS 27 и iPadOS 27 у страницы приложения есть обложка (Header), а в результатах поиска — своя картинка (Search Results). Обе необязательны: без картинки для поиска App Store показывает там скриншоты. По [требованиям Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications) у картинок нет прозрачности, а главное стоит в центре кадра, чтобы не обрезалось на разных устройствах.

| Файл | Вкладка | Размер | Что на картинке |
|---|---|---|---|
| `header-3840x1646.png` | Header, оба языка | 3840 × 1646 (21:9) | иконка Splitway: слева в неё входит одна линия, справа выходят две — яркая прямая (туннель) и тусклая, которая уходит в сторону (прямой путь). Текста нет, поэтому картинка одна на оба языка |
| `search-results-en-3840x2560.png`, `search-results-ru-3840x2560.png` | Search Results | 3840 × 2560 (3:2) | заголовок «Choose which services use the tunnel» / «Выберите сервисы для туннеля» и три экрана iPhone: туннели, выбор сервисов в центре, туннель «Прага» |

На картинках нет цен, адресов сайтов, знака копирайта и логотипов: сервисы каталога показаны монограммами (D-16), а возрастной рейтинг картинок — 4+, как требует Apple.

## Решения

- Название в App Store — Splitway Tunnel (D-43): «Splitway» занято чужой записью. На устройстве приложение называется Splitway, а слово «tunnel» из названия не повторяется в ключевых словах, потому что App Store ищет и по названию.
- Названия чужих сервисов и приложений в текстах не упоминаются (правило 2.3.7): каталог описан словами «мессенджеры, соцсети, видео, музыка и сервисы ИИ».
- «WireGuard» есть в подзаголовке и описании, потому что приложение совместимо с этим протоколом, а в конце описания стоит пометка о товарном знаке. В ключевых словах его нет.
- Описания iOS и macOS разные: на iPhone и iPad выбираются сервисы, на Mac — приложения.
