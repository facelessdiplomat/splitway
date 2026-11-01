# ServiceCatalog

| | |
|---|---|
| Статус | в работе: домен каталога и своих сервисов (M5-02), компилятор плана (M5-03) и встроенный каталог из 15 сервисов (M5-01) готовы; экраны выбора — M5-08, проверка каждого сервиса на устройстве — M5-10 |
| Платформы | iOS, iPadOS |
| Задачи | M5-01, M5-02, M5-03 |
| Таргеты | `ServiceCatalog`, `ServiceCatalogInfrastructure` |

## Назначение

Каталог сервисов для режима «Только выбранные сервисы» (решение D-01): встроенные сервисы (D-15) и свои сервисы пользователя. Компилятор превращает выбор сервисов и конфигурацию туннеля в план маршрутизации: маршруты, домены для `matchDomains`, фиктивные сети и резолверы для движка, а также предупреждения для пользователя. План применяет пакетный туннель ([PacketTunnel](PacketTunnel.md)), трансляцию выполняет движок ([ServiceRouting](ServiceRouting.md)).

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `AppRouting`, `TunnelConfiguration`, `SharedKernel` | `ServiceIdentifier` и `ServiceSelection`; конфигурация туннеля для компилятора; `DomainName`, `IPNetwork`, `IPNetworkSet` |
| Системные фреймворки | Foundation (Infrastructure) | JSON и файлы |
| Сторонние библиотеки | нет | |

## Принцип работы

```mermaid
flowchart LR
  Bundled[catalog.json] --> Load[LoadServiceCatalogUseCase]
  Custom[custom-services.json] --> Load
  Load --> Catalog[ServiceCatalog]
  Selection[ServiceSelection из RoutingPolicy] --> Compiler[ServiceRoutingPlanCompiler]
  Catalog --> Compiler
  Configuration[TunnelConfiguration] --> Compiler
  Compiler --> Plan[ServiceRoutingPlan]
```

### Модель

- `ServiceProfile` — сервис: `ServiceIdentifier`, имя, категория `ServiceCategory` (мессенджеры, соцсети, видео, музыка, ИИ, разработка, свои), иконка `ServiceIcon` (монограмма из одного-двух символов без пробелов и цвет `ServiceTint` в виде `#RRGGBB`, решение D-16), правила `ServiceRules` и `notes` с источниками данных.
- `ServiceRules` — суффиксы доменов и сети. Без единого правила — ошибка `empty`. Суффиксы минимизирует `DomainSuffixSet`: имя, родитель которого тоже есть в наборе, отбрасывается (`t.me` поглощает `a.t.me`). Сети сливает `IPNetworkSet`.
- `CustomService` — свой сервис: идентификатор `custom-<uuid>`, имя и правила. Его `profile` получает категорию `custom`, монограмму из первой буквы имени и нейтральный серый цвет.
- `ServiceCatalog` хранит сервисы без повторов идентификаторов; `services(in:)` отдаёт выбранные в порядке каталога.

### Сценарии

- `LoadServiceCatalogUseCase` читает встроенные сервисы, затем свои.
- `SaveCustomServiceUseCase` сохраняет черновик `CustomServiceDraft`:
  - строки доменов и сетей обрезаются, пустые пропускаются;
  - каждая строка разбирается как `DomainName` или `IPNetwork`, иначе ошибка `invalidDomain` или `invalidNetwork` с текстом строки;
  - без имени — `emptyName`, без правил — `noRules`;
  - новый сервис получает идентификатор, редактируемый заменяется на месте;
  - сбой хранилища — `storageUnavailable`.
- Выбор хранится в политике туннеля: `RoutingPolicy.replacingServiceSelection(with:)` и `RoutingSectionModel.setServices(_:)` ([AppRouting](AppRouting.md)).

### Компилятор плана

`ServiceRoutingPlanCompiler.compile(selection:catalog:configuration:)` строит `ServiceRoutingPlan`:

- **Маршруты:** сети выбранных сервисов внутри `AllowedIPs` всех пиров и фиктивные сети.
- **Домены для `matchDomains`:** минимизированные суффиксы выбранных сервисов.
- **Фиктивные сети** (`FakeNetworkSelection`):
  - IPv4 — `198.18.0.0/15`; IPv6 — `2001:2::/48`, только если у интерфейса есть адрес IPv6;
  - занятыми считаются адреса интерфейса, DNS из конфигурации и адреса endpoint-ов;
  - если предпочтительная сеть занята, берётся свободная половина, а если заняты обе — предпочтительная, с предупреждением.
- **Виртуальный DNS:** третий адрес фиктивной сети IPv4 (`198.18.0.2`).
- **Резолвер для пересылки:** первый IPv4 DNS из конфигурации, иначе `1.1.1.1`.
- **Предупреждения** (`ServiceRoutingWarning`), по порядку:
  - пустой выбор;
  - сети сервиса вне `AllowedIPs`, с самими сетями;
  - домены выбраны, а `AllowedIPs` без `0.0.0.0/0`: настоящие адреса сервисов могут не попасть на сервер;
  - резолвер для пересылки вне `AllowedIPs`;
  - конфликт фиктивной сети.

### Хранение

- `BundledServiceCatalogRepository.bundled` читает `Resources/catalog.json` из ресурсов пакета: `{"schemaVersion": 1, "services": […]}`. Поля записи: `id`, `displayName`, `category`, `monogram`, `tint`, `domainSuffixes`, `ipv4Networks`, `ipv6Networks`, `notes`. Неверная запись — `invalidCatalogEntry(id)`; сеть должна быть своего семейства и без битов хоста.
- `FileCustomServiceRepository(directory:)` (actor) хранит свои сервисы в `custom-services.json` (`schemaVersion: 1`). Запись атомарная, с защитой файла `completeUntilFirstUserAuthentication`, чтобы расширение читало его на заблокированном устройстве. Если файла нет, своих сервисов нет. Приложение и пакетный туннель читают один каталог: `Library/Application Support/Splitway` в контейнере App Group.

### Встроенный каталог (M5-01)

Собран 2026-11-01. Сети взяты только из опубликованных списков, у остальных сервисов — только домены. Источник каждой записи — в её `notes`.

| Сервис | Суффиксы доменов | Сети | Источник сетей |
|---|---|---|---|
| Telegram | `telegram.org`, `t.me`, `telegram.me`, `telegram.dog`, `telesco.pe` | 9 IPv4, 5 IPv6 | `core.telegram.org/resources/cidr.txt` |
| WhatsApp | `whatsapp.com`, `whatsapp.net`, `wa.me` | — | |
| Signal | `signal.org`, `signal.art`, `signal.group`, `signal.link`, `signal.me`, `signal.tube`, `signalcaptchas.org` | — | |
| Instagram | `instagram.com`, `cdninstagram.com`, `ig.me`, `fbcdn.net`, `edge-chat.facebook.com`, `edge-mqtt.facebook.com` | — | |
| Facebook | `facebook.com`, `fbcdn.net`, `fbsbx.com` | — | |
| Threads | `threads.com`, `threads.net`, `cdninstagram.com`, `i.instagram.com`, `edge-chat.facebook.com` | — | |
| YouTube | `youtube.com`, `youtu.be`, `youtube-nocookie.com`, `ytimg.com`, `googlevideo.com`, `youtubei.googleapis.com`, `youtube.googleapis.com`, `yt3.ggpht.com`, `yt3.googleusercontent.com` | — | |
| X | `x.com`, `twitter.com`, `twimg.com`, `t.co`, `pscp.tv` | — | |
| Discord | `discord.com`, `discord.gg`, `discordapp.com`, `discordapp.net`, `discord.media`, `discordsays.com` | — | |
| ChatGPT | `chatgpt.com`, `openai.com`, `oaistatic.com`, `oaiusercontent.com`, `oaistatsig.com` | — | |
| Claude | `claude.ai`, `claude.com`, `anthropic.com`, `claudeusercontent.com`, `claudemcpcontent.com` | 1 IPv4, 1 IPv6 | входящие диапазоны `platform.claude.com/docs/en/api/ip-addresses` |
| Spotify | `spotify.com`, `scdn.co`, `spotifycdn.com` | — | |
| Netflix | `netflix.com`, `nflxvideo.net`, `nflximg.net`, `nflxext.com`, `nflxso.net` | — | |
| LinkedIn | `linkedin.com`, `licdn.com`, `lnkd.in` | — | |
| GitHub | `github.com`, `githubusercontent.com`, `githubassets.com`, `github.dev`, `github.io`, `githubcopilot.com` | 81 IPv4, 2 IPv6 | ключи `web`, `api`, `git` из `api.github.com/meta` |

Домены Telegram, WhatsApp, Signal, Discord, ChatGPT, Claude и GitHub и часть доменов YouTube взяты из документации самих сервисов. Остальные собраны по страницам и клиентам сервисов и помечены в `notes` как неофициальные.

## Публичный API

`ServiceProfile`, `ServiceRules`, `ServiceRulesError`, `ServiceIcon`, `ServiceTint`, `ServiceIconError`, `ServiceCategory`, `ServiceProfileError`, `CustomService`, `CustomServiceDraft`, `CustomServiceError`, `DomainSuffixSet`, `ServiceCatalog`, `ServiceCatalogError`, `ServiceRoutingPlan`, `ServiceRoutingWarning`, `ServiceRoutingPlanCompiler`, `LoadServiceCatalogUseCase`, `SaveCustomServiceUseCase`, порты `BundledServiceCatalog` и `CustomServiceRepository`; адаптеры `BundledServiceCatalogRepository`, `FileCustomServiceRepository`.

## Решения

- Правила — суффиксы доменов, а не точные имена: `matchDomains` в iOS сопоставляет запросы по суффиксам.
- Сеть сервиса вне `AllowedIPs` не маршрутизируется: сервер её пакеты не примет. Пользователь видит предупреждение.
- Идентификаторы своих сервисов начинаются с `custom-` и не пересекаются со встроенными.
- Каталог встроен в приложение и меняется с выпуском новой версии. Обновление по сети — бэклог: это был бы сетевой запрос к серверу разработчика (раздел 4.6 документа iOS).

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Фиктивная сеть IPv6 — `2001:2::/48`, а не ULA, как в первом варианте раздела 4.4 документа iOS | ULA со случайным Global ID (RFC 4193) | Пара к `198.18.0.0/15`: оба блока зарезервированы для тестов производительности (RFC 2544, RFC 5180) и не встречаются ни в интернете, ни в локальных сетях. Префиксы ULA раздают домашние роутеры, и фиктивная сеть могла бы перекрыть адреса локальной сети | Если на устройствах iOS обойдётся с этим блоком иначе, чем с глобальными адресами |
| Голосовые серверы ChatGPT в каталог не входят | Снимок `openai.com/chatgpt-voice.json` (402 адреса Azure) | OpenAI меняет список постоянно: снимок устареет за дни и начнёт отправлять в туннель чужие адреса Azure. Веб и API ChatGPT работают по доменам | Если появится обновление каталога по сети |
| Адреса Azure из `/meta` GitHub входят в каталог | Только собственные сети GitHub | Это официальный список GitHub, и он меняется редко | При каждом обновлении каталога |
| Сервисы Meta делят домены (`fbcdn.net`, `edge-chat.facebook.com`, `cdninstagram.com`) | Только уникальные домены сервиса | Без общих CDN Instagram и Threads не загружают медиа. Выбор Instagram отправляет в туннель и часть трафика Facebook | Нет |
| При полном конфликте остаётся предпочтительная фиктивная сеть | Ошибка компиляции | Пользователь видит предупреждение, а туннель работает для всех адресов, кроме занятых | Если конфликты встретятся на практике |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- Сети есть только у Telegram, Claude и GitHub. Остальные сервисы маршрутизируются только по доменам: приложение со своим DNS (DoH, DoT) или с зашитыми адресами пойдёт мимо туннеля (раздел 4.5 документа iOS).
- Звонки WhatsApp, Signal и Discord и голосовой режим ChatGPT идут на адреса, которые приложения получают внутри своего протокола, и мимо туннеля.
- Аудио Spotify раздают узлы Akamai с общим доменом `akamaized.net`, их в каталоге нет: музыка может идти мимо туннеля.
- Netflix может отказать в воспроизведении через адрес VPN.
- `github.io` отправляет в туннель все сайты GitHub Pages.
- Адреса Azure у GitHub со временем меняются, и снимок нужно обновлять.
- Каждый сервис ещё проверяется на устройстве (M5-10), без этого M5-01 не закрыта.

## Тесты

- 27 тестов в `ServiceCatalogTests`: минимизация и порядок суффиксов, совпадение только по суффиксу; правила без пустого набора и со слиянием сетей; цвет и монограмма иконки; загрузка каталога (встроенные перед своими, выбранные в порядке каталога); сохранение своего сервиса (верные правила, пустое имя, неверные домен и сеть, без правил, замена редактируемого); компилятор (маршруты и фиктивная сеть, часть внутри `AllowedIPs` с предупреждением, только самые короткие домены выбранных сервисов, IPv6 только при адресе IPv6, сдвиг фиктивной сети от адресов туннеля, виртуальный DNS внутри фиктивной сети, первый IPv4 DNS туннеля, предупреждения о пустом выборе и о резолвере вне `AllowedIPs`, один план при любом порядке выбора).
- 9 тестов в `ServiceCatalogInfrastructureTests`: все поля записи каталога, запись с неверным доменом называется по `id`, нет каталога, чужая версия схемы; 15 стартовых сервисов по порядку, у каждого есть домены и источник; свои сервисы читаются после записи, нечитаемый документ, пустой список до первой записи.
- `ServiceCatalogTestSupport`: `ServiceCatalogFixtures`, `FixedBundledServiceCatalog`, `InMemoryCustomServiceRepository`, `UnavailableCustomServiceRepository`.

Запуск: `swift test --package-path Packages/SplitwayKit --filter ServiceCatalog`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-11-01 | Модель сервисов и своих правил, чтение встроенного каталога и хранение своих сервисов | M5-02 |
| 2026-11-01 | Компилятор плана маршрутизации | M5-03 |
| 2026-11-01 | Встроенный каталог из 15 сервисов | M5-01 |
