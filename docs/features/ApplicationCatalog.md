# ApplicationCatalog

| | |
|---|---|
| Статус | в работе: Core, сканирование, подписи и иконки готовы; экран выбора — M4-04 |
| Платформы | macOS |
| Задачи | M4-02, M4-03 |
| Таргеты | `ApplicationCatalog`, `ApplicationCatalogInfrastructure`, `ApplicationCatalogTestSupport` |

## Назначение

Каталог приложений и CLI-утилит Mac для режима «Только выбранные приложения». Фича ищет и фильтрует установленные приложения и собирает для выбранного приложения `ApplicationIdentity`: signing identifier главного бандла и его хелперов, Team ID, путь и версию. По этой идентичности `AppRouting` узнаёт процессы выбранного приложения.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `SharedKernel`, `AppRouting` | `ApplicationIdentity`, `ApplicationKind`, `ApplicationSelection` |
| Системные фреймворки | Foundation; в `Infrastructure` (только macOS) — Security, AppKit, Synchronization | поиск и сортировка строк; подписи кода; запущенные приложения и иконки; кэш |
| Сторонние библиотеки | нет | |

## Принцип работы

- `InstalledApplication` — то, что нашёл сканер: вид (приложение или CLI-утилита), имя, bundle ID, путь и версия. Подписи сканер не читает: на типичном Mac сотни приложений, а подпись нужна только выбранным.
- `ApplicationCatalogQuery` фильтрует и сортирует список:
  - поиск по имени без учёта регистра и диакритики (`localizedStandardContains`), пробелы по краям запроса не важны;
  - фильтр `ApplicationCatalogFilter`: все, выбранные, только CLI-утилиты;
  - сортировка по имени как в Finder (`localizedStandardCompare`): «App 2» раньше «App 10».
- `ApplicationIdentityBuilder` собирает идентичность из `BundleCodeSignatures`, то есть подписи главного бандла и вложенного кода:
  - signing identifier главного бандла и вложенного кода той же команды (хелперы Chrome и Electron);
  - вложенный код другой команды пропускается: `ApplicationMatcher` всё равно требует Team ID выбранного приложения;
  - неподписанное приложение получает идентичность без identifiers и узнаётся по пути.
- Сценарии:
  - `LoadInstalledApplicationsUseCase` отдаёт найденное по имени;
  - `ResolveApplicationIdentityUseCase` читает подписи через `CodeSignatureReader` и собирает идентичность; если подпись прочитать нельзя, остаётся сопоставление по пути;
  - `RefreshSelectedApplicationsUseCase` пересобирает идентичность выбранного приложения, когда сменилась версия его бандла (`ApplicationIdentity.bundleVersion`). Приложения без изменений и пропавшие остаются как были.
- Порты: `ApplicationBundleScanner` (найти приложения), `CodeSignatureReader` (подписи бандла и вложенного кода), `ApplicationIconLoader` (иконка по пути, для экрана выбора).

**Адаптеры macOS** (`ApplicationCatalogInfrastructure`):

- `FileSystemApplicationScanner` ищет бандлы `.app`:
  - в `/Applications`, `/Applications/Utilities`, `/Applications/Setapp`, `/System/Applications`, `/System/Applications/Utilities`, `~/Applications` и на один уровень глубже (папки вроде «Microsoft Office»);
  - среди запущенных обычных приложений (`NSWorkspace.runningApplications`), чтобы найти приложение в любом месте.

  Повторы убираются по реальному пути: `/Applications/Safari.app` — ссылка в криптекс. Имя — локализованное имя Finder без `.app`, bundle ID и версия — из `Info.plist`. Результат кэшируется по пути и дате изменения `Info.plist`, а сканирование идёт на своей очереди.
- `SecurityCodeSignatureReader` читает signing identifier и Team ID через `SecStaticCodeCreateWithPath` и `SecCodeCopySigningInformation` — у самого бандла и у вложенного кода, который нашёл `NestedCodeEnumerator`. Тоже на своей очереди.
- `NestedCodeEnumerator` ищет вложенные `.app`, `.xpc`, `.appex` и исполняемые файлы папок `Helpers` в `Contents/Frameworks`, `Contents/XPCServices`, `Contents/Helpers`, `Contents/Library/LoginItems`, `Contents/PlugIns`. `Contents/Resources` не просматривается: там лежат образцы, а не код приложения. У Electron-приложений так находятся `Helper.app`, `Helper (Renderer).app` и `Helper (GPU).app` с общим identifier хелпера и той же командой (проверено на установленном Electron-приложении).
- `WorkspaceIconLoader` рисует иконку `NSWorkspace.icon(forFile:)` в PNG 64 × 64 точки на своей очереди и кэширует её по пути.
- `ApplicationCatalogAssembly` собирает сценарии и загрузчик иконок для composition root.

## Публичный API

`InstalledApplication`, `CodeSignature`, `BundleCodeSignatures`, `ApplicationCatalogQuery`, `ApplicationCatalogFilter`, `ApplicationIdentityBuilder`; порты `ApplicationBundleScanner`, `CodeSignatureReader`, `CodeSignatureReadingError`, `ApplicationIconLoader`; сценарии `LoadInstalledApplicationsUseCase`, `ResolveApplicationIdentityUseCase`, `RefreshSelectedApplicationsUseCase`; адаптеры macOS `FileSystemApplicationScanner`, `SecurityCodeSignatureReader`, `NestedCodeEnumerator`, `WorkspaceIconLoader`, `ApplicationCatalogAssembly`.

## Решения

- Подписи читаются при выборе, а не при сканировании: сканирование остаётся быстрым, а выбор — один бандл.
- Версия бандла хранится в `ApplicationIdentity` (`bundleVersion`) необязательным полем: старые сохранённые политики читаются без изменения версии схемы.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Вложенный код другой команды не входит в идентичность | Хранить пары «identifier → Team ID» для каждого вложенного бандла | `ApplicationMatcher` требует Team ID выбранного приложения, и такие identifiers всё равно не совпали бы | Если встретятся приложения с хелперами другой команды |
| Нечитаемая подпись — выбор по пути, а не отказ | Не давать выбрать приложение | Пользователь всё равно может выбрать приложение; путь надёжен, пока приложение не переместили | Нет |
| Пропавшее приложение остаётся в выборе | Удалять из выбора | Приложение может быть на отключённом диске или переустанавливаться | Если пользователи начнут путаться в старых записях |
| Без Spotlight (`NSMetadataQuery`) | Искать бандлы через Spotlight | Стандартные папки и запущенные приложения покрывают почти всё, остальное пользователь перетащит сам (M4-04); запрос Spotlight требует цикла событий и асинхронной сборки результатов | Если пользователи не найдут свои приложения |
| Сканирование на один уровень вглубь | Полный обход папок | Папки производителей содержат бандлы на первом уровне, а полный обход дорог | Если встретятся приложения глубже |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- Экран выбора — M4-04.
- Адаптеры собираются только для macOS (`#if os(macOS)`): на iOS выбор приложений не поддерживается.

## Тесты

10 тестов в `ApplicationCatalogTests`:

- поиск без учёта регистра и диакритики, фильтры выбранных и CLI-утилит, сортировка как в Finder;
- идентичность браузера с хелперами той же команды и без кода другой команды; неподписанное приложение, которое `ApplicationMatcher` узнаёт по пути;
- сценарии: список по имени, идентичность из подписей, запасной путь при нечитаемой подписи, пересборка после обновления, без изменений для прежней версии и пропавшего приложения.

5 тестов в `ApplicationCatalogInfrastructureTests` (только macOS):

- подписи Safari (`com.apple.Safari`), Terminal (`com.apple.Terminal`) и `/usr/bin/curl` (`com.apple.curl`) — без Team ID, как у кода Apple; несуществующий бандл;
- вложенный код бандла-фикстуры: хелпер внутри фреймворка, служба XPC, исполняемый файл `Helpers`, а приложение в `Resources` пропускается;
- сканирование фикстуры: приложения на первом уровне и на один уровень глубже, без повторов через ссылку, имена, bundle ID и версии;
- прогретое сканирование этого Mac быстрее 2 секунд. Здесь около 95 бандлов, и на каждый уходит один запрос метаданных `Info.plist`, так что 200+ приложений тоже укладываются.

Запуск: `swift test --package-path Packages/SplitwayKit --filter ApplicationCatalog`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-30 | Каталог приложений: поиск, фильтры, сборка идентичности, обновление выбранных | M4-02 |
| 2026-10-30 | Сканирование приложений, подписи и вложенный код, иконки | M4-03 |
