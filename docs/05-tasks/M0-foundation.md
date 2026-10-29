# M0. Фундамент и спайки

Цель: пустой, но полностью собираемый проект на всех платформах, с линтерами, локальными проверками и сборкой Go-ядра. Плюс ответы на технические вопросы с наибольшим риском, до того как на них будет опираться код.

## Статус

- [ ] M0-01 Решения до старта
- [x] M0-02 Git-репозиторий и базовые файлы
- [ ] M0-03 Активировать Xcode как основной тулчейн
- [ ] M0-04 Идентификаторы и профили в Apple Developer
- [x] M0-05 SPM-пакет SplitwayKit
- [ ] M0-06 Проект XcodeGen и оболочки таргетов
- [x] M0-07 Линтеры и форматирование
- [x] M0-08 Go-модуль TunnelCore и сборка xcframework
- [ ] M0-09 Локальная проверка `Scripts/check.sh`
- [ ] M0-10 Тестовый WireGuard-сервер
- [ ] SP-7 Hello tunnel: wireguard-go в пакетном туннеле
- [ ] SP-2 Атрибуция потоков в transparent proxy
- [ ] SP-6 UDP и QUIC в transparent proxy
- [ ] SP-9 Атрибуция DNS-запросов в DNS-прокси
- [ ] SP-3 Скорость ретрансляции через netstack
- [ ] SP-5 Секреты в системном расширении
- [ ] SP-4 Прототип выбора сервисов на iOS
- [ ] M0-11 Точка решения по итогам спайков

## Подготовка

### M0-01. Решения до старта
`shared` · S · зависит от: —

**Сделать:** название (Splitway, D-13) и минимальные ОС (D-04) уже решены. Получить от владельца префикс bundle ID; проверить, что название свободно (App Store, домен, базы товарных знаков); записать идентификаторы в [журнал решений](../00-decisions.md) и в `project.yml`.
**Тесты сначала:** не требуются (решение, не код).
**Готово, когда:** известны bundle ID приложения и расширений, App Group и Keychain group; проверка названия не выявила конфликтов.

### M0-02. Git-репозиторий и базовые файлы
`shared` · S · зависит от: M0-01

**Сделать:** `git init`, ветка `main`; `.gitignore` (DerivedData, `.build`, `*.xcodeproj` — генерируется XcodeGen, `Packages/TunnelCore/build`, `*.xcframework`, `.DS_Store`); `.gitattributes`; `LICENSE` с проприетарной лицензией (решение D-14); корневой `README.md`. Автор коммитов — владелец репозитория, без соавторов-ИИ.
**Тесты сначала:** не требуются.
**Готово, когда:** первый коммит содержит документацию и базовые файлы; `git log` показывает только автора-человека.

### M0-03. Активировать Xcode как основной тулчейн
`shared` · S · зависит от: —

**Сделать:** сейчас `xcode-select` указывает на Command Line Tools, поэтому `xcodebuild` недоступен. Владельцу выполнить (нужен пароль администратора):
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` и `sudo xcodebuild -runFirstLaunch`.
**Тесты сначала:** не требуются.
**Готово, когда:** `xcodebuild -version` показывает Xcode 27.x.

### M0-04. Идентификаторы и профили в Apple Developer
`shared` · M · зависит от: M0-01

**Сделать:** App ID для `iOSApp`, `PacketTunnelExtension`, `ControlsExtension`, `macOSApp`, `NetworkSystemExtension`; возможности Network Extensions, System Extension (macOS), App Groups, Keychain Sharing; App Group для iOS и macOS; Development- и Developer ID-профили, Ad Hoc-профиль для iOS; регистрация тестовых устройств.
**Тесты сначала:** не требуются.
**Готово, когда:** все профили скачаны или подтягиваются автоматической подписью, Developer ID Application-сертификат установлен.

## Каркас кода

### M0-05. SPM-пакет SplitwayKit
`shared` · S · зависит от: M0-02

**Сделать:** `Packages/SplitwayKit/Package.swift` (Swift 6, платформы из M0-01). Вспомогательная функция объявления фичи, которая создаёт таргеты `<Feature>`, `<Feature>Infrastructure`, `<Feature>Presentation` и их тестовые таргеты по структуре из [02-architecture.md](../02-architecture.md), раздел 4. Первый таргет — `SharedKernel` и `SharedKernelTests`.
**Тесты сначала:** один тест в `SharedKernelTests`, проверяющий, что пакет собирается и тесты запускаются.
**Готово, когда:** `swift test --package-path Packages/SplitwayKit` проходит.

### M0-06. Проект XcodeGen и оболочки таргетов
`shared` · M · зависит от: M0-04, M0-05

**Сделать:** `project.yml` с таргетами `iOSApp`, `macOSApp`, `PacketTunnelExtension`, `NetworkSystemExtension` (`ControlsExtension` добавляется в M6). Файлы entitlements и `Info.plist` из [03-platform-macos.md](../03-platform-macos.md) и [04-platform-ios-ipados.md](../04-platform-ios-ipados.md). Настройки сборки: Swift 6, strict concurrency, Hardened Runtime (macOS), встраивание системного расширения в `Contents/Library/SystemExtensions`. Пустые точки входа: SwiftUI-окно, провайдеры с методами-заглушками. Скрипт `Scripts/generate-project.sh`.
**Тесты сначала:** не требуются (конфигурация сборки).
**Готово, когда:** все таргеты собираются для симулятора iOS и для macOS; системное расширение лежит внутри `.app`.

### M0-07. Линтеры и форматирование
`shared` · M · зависит от: M0-05

**Сделать:**
- `.swiftlint.yml`: кастомное правило `no_comments` (`match_kinds: [comment, doccomment, comment.mark, comment.url, doccomment.field]`); правило `core_layer_imports`: файлы в `/Core/` не импортируют `SwiftUI`, `UIKit`, `AppKit`, `NetworkExtension`, `Security`, `SystemExtensions`; запрет `print`, `force_unwrapping`, `force_try` вне тестов; лимиты длины типов и функций (предупреждения).
- `swift format` с конфигурацией `.swift-format`.
- `Scripts/go-comment-check`: небольшая Go-программа на `go/ast`, которая падает на любом комментарии, кроме директив (`//go:`, `//export`, преамбулы cgo).
- Git-хуки в `Scripts/git-hooks/`: `pre-commit` (форматирование и линтер), `commit-msg` (отклоняет трейлеры `Co-Authored-By` с ИИ и строки «Generated with…», проверяет формат Conventional Commits), `pre-merge-commit` (запускает `Scripts/check.sh` из M0-09). Установка через `Scripts/bootstrap.sh`.
- `Scripts/lint.sh` запускает всё сразу.

**Тесты сначала:** фикстуры с комментариями: Swift-файл и Go-файл должны вызывать ошибку линтера, файл без комментариев — нет. Для Go-чекера — тесты в `go test`.
**Готово, когда:** `Scripts/lint.sh` ловит комментарий в Swift и Go и пропускает директивы; хук `commit-msg` отклоняет сообщение с ИИ-трейлером.

### M0-08. Go-модуль TunnelCore и сборка xcframework
`shared` · L · зависит от: M0-05

**Сделать:** `Packages/TunnelCore/go/go.mod` (зависимость `golang.zx2c4.com/wireguard` с закреплённой версией появляется вместе с первым импортом в M2-03: неиспользуемую зависимость удалил бы `go mod tidy`); пакет `bridge` с `tc_version` и `tc_free`. `Scripts/build-xcframework.sh`: `-buildmode=c-archive` для `ios-arm64`, `ios-arm64-simulator`, `macos-arm64`, `macos-x86_64`, `lipo`, заголовок и `module.modulemap`, `xcodebuild -create-xcframework`; кэш по хэшу Go-исходников. `Packages/TunnelCore/Package.swift`: `binaryTarget` `TunnelCoreFramework` и таргет `TunnelCoreAdapter`, вызывающий `tc_version`.
**Тесты сначала:** Go-тест на `tc_version`; Swift-тест в `TunnelCoreAdapterTests`, что версия читается и память освобождается.
**Готово, когда:** скрипт собирает xcframework с нуля и при повторном запуске пропускает сборку; оба теста зелёные.

### M0-09. Локальная проверка `Scripts/check.sh`
`shared` · M · зависит от: M0-06, M0-07, M0-08

**Сделать:** CI нет (решение D-23), его заменяет один скрипт: сборка xcframework (с кэшем), `Scripts/lint.sh`, `go test ./...`, `swift test` для SplitwayKit, `xcodebuild build test` для iOS-симулятора и macOS без подписи. Флаги: `--ui` (UI-тесты), `--bench` (бенчмарки). Хук `pre-merge-commit` запускает скрипт при слиянии ветки в `main` через `git merge --no-ff` (решение D-26).
**Тесты сначала:** не требуются (скрипт сам запускает тесты).
**Готово, когда:** слияние ветки с намеренно добавленным комментарием в коде отклоняется хуком, а чистой ветки — проходит.

### M0-10. Тестовый WireGuard-сервер
`shared` · S · зависит от: —

**Сделать:** `Scripts/test-server/`: контейнер (или инструкция для VM) с WireGuard, генерация пиров для iOS и macOS, скрипт выдачи конфигов. Описание запуска в `Scripts/test-server/README.md`. Тестовые ключи не используются нигде, кроме этого сервера.
**Тесты сначала:** не требуются.
**Готово, когда:** официальный клиент WireGuard подключается к серверу по выданному конфигу.

## Спайки (параллельно с M1)

Спайк — одноразовый прототип в отдельной ветке `spike/SP-x`. В `main` не сливается. Результат — документ `docs/features/spikes/SP-x.md`: что проверили, цифры, вывод, влияние на план. Код спайка можно писать быстро, но выводы обязаны быть подтверждены на реальном устройстве.

### SP-7. Hello tunnel: wireguard-go в пакетном туннеле
`iOS+iPadOS`, `macOS` · L · зависит от: M0-06, M0-08, M0-10

**Сделать:** минимальный `PacketTunnelProvider`: поиск дескриптора `utun`, запуск wireguard-go с захардкоженным тестовым конфигом, применение сетевых настроек на iPhone и macOS (системное расширение).
**Готово, когда:** рукопожатие проходит, `curl` показывает IP тестового сервера; замерена базовая память расширения на iOS.

### SP-2. Атрибуция потоков в transparent proxy
`macOS` · M · зависит от: M0-06

**Сделать:** `TransparentProxyProvider`, который логирует метаданные каждого потока (`sourceAppSigningIdentifier`, audit token → путь и Team ID, `remoteHostname`, адрес) и всегда возвращает `false`.
**Готово, когда:** таблица по Safari, WKWebView-приложению, Chrome, Firefox, Electron (Slack/Discord), Telegram, `curl`, `ssh`, `nsurlsessiond`; подтверждено, что возврат `false` не ломает поток.

### SP-6. UDP и QUIC в transparent proxy
`macOS` · M · зависит от: SP-2

**Сделать:** перехват `handleNewUDPFlow(_:initialRemoteEndpoint:)` для выбранного приложения и ретрансляция «как есть» через сокет расширения.
**Готово, когда:** HTTP/3 в Chrome и голосовой звонок работают через перехват, без зависаний потоков.

### SP-9. Атрибуция DNS-запросов в DNS-прокси
`macOS` · M · зависит от: SP-2

**Сделать:** `DNSProxyProvider` в том же системном расширении логирует метаданные каждого DNS-потока и пересылает запрос исходному резолверу без изменений. Спайк SP-1 (системный per-app VPN) отменён решением D-11.
**Готово, когда:** есть таблица «приложение → что видно в метаданных DNS-запроса» для приложений из SP-2; подтверждено, что все провайдеры работают в одном процессе и могут делить `usernet`; описано, что происходит с DNS системы при падении и остановке прокси.

### SP-3. Скорость ретрансляции через netstack
`macOS` · L · зависит от: SP-2, SP-7

**Сделать:** прототип `usernet` (wireguard-go + gVisor netstack) и TCP-ретрансляция одного потока между `NEAppProxyTCPFlow` и netstack.
**Готово, когда:** замерены скорость (iperf3 / загрузка файла) и задержка против режима «Весь трафик», профиль CPU; зафиксирована целевая метрика для M4-16.

### SP-5. Секреты в системном расширении
`macOS` · M · зависит от: SP-7

**Сделать:** проверить варианты A, B, C из [03-platform-macos.md](../03-platform-macos.md), раздел 5: доступ root-расширения к элементу по `passwordReference`; XPC через `NEMachServiceName` + запись в System Keychain; `providerConfiguration`.
**Готово, когда:** выбран вариант, описаны права доступа и поведение после обновления и переустановки.

### SP-4. Прототип выбора сервисов на iOS
`iOS+iPadOS` · L · зависит от: SP-7

**Сделать:** `matchDomains` для двух доменов, виртуальный DNS, фиктивный адрес и DNAT в Go-обёртке над `tun.Device`.
**Готово, когда:** выбранный домен открывается через туннель, остальные — напрямую; пиковая память под нагрузкой ≤ 35 МБ; описано поведение после выключения VPN.

### M0-11. Точка решения по итогам спайков
`shared` · S · зависит от: SP-2…SP-7, SP-9

**Сделать:** обновить ADR-02, ADR-11 и таблицы рисков в документах платформ; скорректировать задачи M2, M4, M5 и оценки.
**Тесты сначала:** не требуются.
**Готово, когда:** документация отражает фактические результаты спайков, и план M2–M5 подтверждён или изменён.
