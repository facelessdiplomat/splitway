# TunnelLibrary

| | |
|---|---|
| Статус | в работе: Core, хранилища и экран списка готовы; запуск на macOS и прогон Keychain там ждут M0-04, передача секрета в системное расширение — M2-12 |
| Платформы | shared |
| Задачи | M1-11, M1-12, M1-13, M1-14, M1-15 (экспорт в ZIP), M3-02 |
| Таргеты | `TunnelLibrary`, `TunnelLibraryInfrastructure`, `TunnelLibraryPresentation`, `TunnelLibraryTestSupport` |

## Назначение

Библиотека туннелей пользователя: сущность `Tunnel` и правила имён; сценарии создания, импорта, изменения, переименования, удаления, дублирования, сортировки и экспорта. Метаданные и секреты хранятся раздельно и согласованно. Слой `Presentation` показывает список туннелей с состоянием подключения и корневую навигацию приложения.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `SharedKernel`, `TunnelConfiguration`, `AppRouting`; в `Presentation` — `TunnelConnection`, `DesignSystemPresentation` | часы, конфигурация туннеля, политика маршрутизации; состояние слота и подключение; общие компоненты |
| Системные фреймворки | Foundation, Security, SwiftUI, Observation | файлы и JSON; Keychain; экран списка |
| Сторонние библиотеки | ZIPFoundation 0.9.20, MIT | архив при экспорте (решение D-21) |

## Принцип работы

```mermaid
flowchart LR
  UseCases[Сценарии] --> Persistence[TunnelPersistence]
  Persistence --> Records[(TunnelRecordRepository: tunnels.json)]
  Persistence --> Secrets[(TunnelSecretStore: Keychain)]
  UseCases --> Archive[ArchiveWriter: ZIP]
  UseCases --> Probe[TunnelActivityProbe]
```

**Модель.**

- `Tunnel` — id, имя, конфигурация и политика маршрутизации.
- `TunnelRecord` — та же запись без секретов (id, имя, политика), её хранит `TunnelRecordRepository`. Текст конфигурации с ключами хранит `TunnelSecretStore` под id туннеля.
- `TunnelName` — 1…64 символа после обрезки пробелов, без управляющих символов. `derived(fromFileName:)` получает имя из имени файла, `UniqueTunnelNameResolver` подбирает свободное: «Office», «Office 2» (регистр не учитывается).

**Сценарии.**

- Все сценарии работают через `TunnelPersistence`. Сохранение согласованное: если запись метаданных не удалась, секрет откатывается — новый удаляется, прежний восстанавливается.
- `LoadTunnelsUseCase` возвращает `TunnelLibrarySnapshot` — записи в сохранённом порядке. Каждая запись `TunnelLibraryEntry` либо читаемый туннель, либо нечитаемая запись: нет секрета, секрет повреждён или не разбирается. Нечитаемая запись остаётся на своём месте.
- `DeleteTunnelUseCase` сначала останавливает активный туннель через `TunnelActivityProbe`.
- `ExportTunnelsUseCase` выдаёт один конфиг или архив всех туннелей с уникальными именами файлов (`ExportFileNaming`).

**Адаптеры.**

- `FileTunnelRecordRepository` (actor) хранит `tunnels.json` в директории, которую передаёт composition root (контейнер App Group).
  - Запись атомарная, с классом защиты `completeUntilFirstUserAuthentication`.
  - В документе есть версия схемы, старые версии обновляет `JSONDocumentMigrator`: текущая версия равна 1 + число шагов.
  - Повреждённый документ переносится в `tunnels.corrupted-<время UTC>.json`, сценарий получает `corruptedData`, библиотека начинается пустой.
  - Документ более новой версии остаётся на месте, сценарий получает `unsupportedSchemaVersion`.
- `KeychainTunnelSecretStore` хранит generic password в data protection keychain: service `Splitway tunnel configuration`, account — UUID туннеля, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, без синхронизации. Access group передаёт composition root.
- `ZIPArchiveWriter` пишет архив: deflate, имена в UTF-8, права `0600`.
- `TunnelLibraryAssembly` собирает граф фичи для composition root: директория хранения и access group Keychain приходят снаружи, проба активности — из `TunnelConnection`.

**Экран списка.**

- `TunnelListModel` (`@MainActor`, `@Observable`) объединяет записи библиотеки и `SlotState` в строки `TunnelRow`: имя, `TunnelRowStatus`, режим маршрутизации.
  - Статус берётся из слота только для туннеля, который в нём записан; остальные — «Отключён».
  - Нечитаемая запись — строка «Конфигурация недоступна»: её можно удалить и переставить, но не подключить и не дублировать.
- Действия модели: переключить подключение, удалить с подтверждением (`TunnelDeletionRequest`, предупреждает, если туннель подключён), дублировать, переставить. Перестановка применяется сразу и сохраняется через `ReorderTunnelsUseCase`; при ошибке список перечитывается.
- Ошибки сценариев показываются через `TunnelListAlert`.
- `TunnelLibraryRootView` — `NavigationSplitView`: список в боковой колонке, детали туннеля справа. На iPhone SwiftUI сворачивает его в стек. Корень загружает библиотеку и наблюдает за слотом, пока виден.
- Способы добавления туннеля (`TunnelAdditionMethod`) и их обработчик передаёт composition root через `TunnelAdditionOptions`. Меню «+» и кнопки пустого состояния показывают только переданные способы.

## Публичный API

- **Модель:** `Tunnel`, `TunnelIdentifier`, `TunnelName`, `TunnelNameError`, `TunnelRecord`, `UniqueTunnelNameResolver`, `ExportedConfigurationFile`.
- **Порты:** `TunnelRecordRepository`, `TunnelSecretStore`, `TunnelActivityProbe`, `ArchiveWriter` и их ошибки `TunnelStorageError`, `TunnelActivityError`, `ArchiveWritingError`.
- **Сценарии:** `LoadTunnelsUseCase` (`TunnelLibrarySnapshot`, `TunnelLibraryEntry`), `CreateTunnelUseCase`, `ImportTunnelsUseCase` (`ImportCandidate`, `ImportReport`, `ImportFailure`), `UpdateTunnelUseCase`, `RenameTunnelUseCase`, `DeleteTunnelUseCase`, `DuplicateTunnelUseCase`, `ReorderTunnelsUseCase`, `ExportTunnelsUseCase`, ошибка `TunnelLibraryError`.
- **Адаптеры:** `FileTunnelRecordRepository`, `JSONDocumentMigrator`, `JSONDocumentMigrationError`, `KeychainTunnelSecretStore`, `ZIPArchiveWriter`, сборка `TunnelLibraryAssembly`.
- **Экран:** `TunnelListModel`, `TunnelRow`, `TunnelRowStatus`, `TunnelDeletionRequest`, `TunnelListAlert`, `TunnelLibraryActions`, `TunnelConnectionActions`, `TunnelAdditionMethod`, `TunnelAdditionOptions`, `TunnelLibraryRootView`.

## Решения

- В `tunnels.json` никогда нет ключей. Keychain — главная копия секретов на обеих платформах.
- Порты бросают `TunnelStorageError`, сценарии — `TunnelLibraryError`.
- Директорию App Group и access group Keychain передаёт composition root. Адаптеры не знают идентификаторов, а тесты работают во временной директории и с отдельным service.
- Корень наблюдает за слотом сам, а не список: на iPhone список уходит со стека, когда открыты детали, и его `task` отменился бы.
- Вью вызывают асинхронные действия через `Task.immediate`: перестановка и снятие запроса на удаление выполняются синхронно в обработчике жеста, и `List` не возвращает строку на прежнее место.
- Кнопка удаления в свайпе — без роли `destructive`, с красным цветом: роль `destructive` заставляет `List` сразу анимировать удаление строки, хотя пользователь ещё не подтвердил его. В контекстном меню роль остаётся.
- Диалог подтверждения привязан к своей строке (`deletionRequest(for:)`), поэтому на iPad и в iOS 26 всплывающее окно указывает на удаляемый туннель.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Повреждённый `tunnels.json` переносится в резервную копию, библиотека начинается пустой | Оставлять файл и показывать ошибку при каждом запуске; читать уцелевшие записи | Ошибка показывается один раз, данные не теряются (копия лежит рядом), приложение остаётся рабочим. Частичное чтение потеряло бы нечитаемые записи при следующем сохранении | Когда появится восстановление из копии |
| Ужесточение валидации записей требует миграции схемы | Пропускать записи, не прошедшие проверку | Иначе новая версия приложения сочтёт старые данные повреждёнными целиком | Нет |
| `FileTunnelRecordRepository` вместо `AppGroupTunnelRepository` из плана | `AppGroupTunnelRepository` | Адаптер работает с любой директорией; App Group — выбор composition root | Нет |
| Шаги миграции — массив, текущая версия = 1 + число шагов | Словарь «версия → миграция» | Пропуск версии невозможен по построению | Если понадобятся миграции через версию |
| Шаги миграции работают с `[String: Any]` из `JSONSerialization` | Свой тип `JSONValue`; типизированные документы по версиям | Миграции редки, дерево JSON — стандартный инструмент без нового кода | При первой сложной миграции |
| Секрет хранится как текст wg-quick | Отдельные поля ключей | Один формат для импорта, экспорта и движка | Если понадобится обновлять ключи по отдельности |
| Сохранение секрета: добавление, при `errSecDuplicateItem` — обновление | Удаление и добавление | Нет момента, когда секрета нет | Нет |
| Ошибки Keychain сводятся к `unavailable` без `OSStatus` | Передавать код наверх | Сценарии не различают причины | Когда журнал начнёт записывать ошибки хранилищ (M2) |
| Интеграционные тесты Keychain — в таргете `iOSIntegrationTests` с хост-приложением | Тесты в SPM | Data protection keychain требует entitlements, `swift test` их не даёт | Нет |
| Один `NavigationSplitView` на всех устройствах | `NavigationStack` на iPhone и `NavigationSplitView` на iPad и Mac, как в плане M3-02 | В компактной ширине SwiftUI сам сворачивает его в стек; второй вариант навигации дублировал бы код и ломался бы в Slide Over | Если появятся экраны, которым нужен свой стек на iPhone |
| Способы добавления туннеля передаёт composition root | Кнопки импорта прямо в фиче | Импорт и редактор — другие фичи (`TunnelImport`, `TunnelEditor`), а набор способов зависит от платформы (QR только на iOS). Пока способов нет, кнопок нет, а не пустых действий | Нет |
| Детали туннеля до M3-03 строятся из строки списка | Заглушка «скоро» | Экран полезен уже сейчас: переключатель, статус, режим. `TunnelDetailModel` со статистикой заменит его в M3-03 | M3-03 |
| Текст ошибки подключения пока общий | Текст для каждой `ConnectionFailure` сразу | Сообщения с советами — отдельная задача M3-09 с собственными тестами | M3-09 |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- Прогон тестов Keychain на macOS ждёт Team ID и профиль (M0-04): без entitlements data protection keychain на macOS недоступен.
- Секреты туннелей из повреждённого `tunnels.json` остаются в Keychain без записей.
- Запись `tunnels.json` из нескольких процессов не координируется. Пишет только приложение; расширение и интенты читают, а атомарное переименование защищает читателей.
- Системное расширение macOS работает от root и не видит Keychain пользователя. Копию секрета ему передаёт M2-12.
- Экран списка проверен в симуляторах iPhone и iPad: светлая и тёмная тема, русский язык, псевдолокализация, удаление, дублирование, перестановка, ошибка подключения. Приложение macOS собирается, но без подписи с ограниченными entitlements не запускается (M0-04).
- В симуляторе NetworkExtension не работает (`IPC failed`), поэтому подключение там всегда заканчивается сообщением об ошибке. Смена статуса на экране проверена тестами модели, на устройстве — в M2-14.

## Тесты

- 34 теста в `TunnelLibraryTests`: каждый сценарий с фейками из `TunnelLibraryTestSupport`, откаты при сбоях хранилищ, импорт с частичными неудачами и конфликтами имён, удаление активного туннеля, экспорт, порядок нечитаемых записей.
- 20 тестов в `TunnelLibraryInfrastructureTests`:
  - репозиторий во временной директории;
  - эталонный документ версии 1 читается и записывается;
  - повреждённый документ, новая версия схемы, ошибки доступа;
  - мигратор;
  - ZIP-экспорт с именами в UTF-8 и правами `0600`.
- 7 интеграционных тестов Keychain в `iOSIntegrationTests` на симуляторе iPhone: запись, перезапись, удаление, чтение отсутствующего, атрибуты доступности и синхронизации.
- 17 тестов в `TunnelLibraryPresentationTests`:
  - модель списка: строки и состояние слота, нечитаемые записи на своих местах, пустое состояние только после загрузки;
  - подтверждение удаления, в том числе для подключённого туннеля, отмена, привязка к строке;
  - перестановка через `ReorderTunnelsUseCase`, дублирование, переключение подключения, ошибка подключения;
  - статусы строк: каждое `ConnectionState`, тон и активность.

Запуск: `swift test --package-path Packages/SplitwayKit --filter TunnelLibrary`. Интеграционные тесты запускает `Scripts/check.sh`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-29 | `Tunnel`, `TunnelName`, уникальные имена | M1-11 |
| 2026-10-29 | Порты и сценарии библиотеки | M1-12 |
| 2026-10-29 | `FileTunnelRecordRepository` и `JSONDocumentMigrator` | M1-13 |
| 2026-10-29 | `KeychainTunnelSecretStore`, интеграционные тесты на симуляторе | M1-14 |
| 2026-10-29 | `ZIPArchiveWriter` | M1-15 |
| 2026-10-29 | Экран списка, корневая навигация, сборка фичи; записи снимка в сохранённом порядке | M3-02 |
