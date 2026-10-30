# SecretDelivery

| | |
|---|---|
| Статус | в работе: Core готов; адаптеры XPC (`NEMachServiceName`) и System Keychain — после спайка SP-5 и подписи (M0-04) |
| Платформы | macOS |
| Задачи | M2-12 |
| Таргеты | `SecretDelivery`, `SecretDeliveryTestSupport` |

## Назначение

Системное расширение macOS работает от root и не видит Keychain пользователя, где приложение хранит конфигурации туннелей. Фича доставляет расширению копию секрета по варианту B из [03-platform-macos.md](../03-platform-macos.md), раздел 5: приложение передаёт текст конфигурации по XPC, расширение кладёт его в System Keychain. Секрет не лежит ни в одном plist, а расширение может поднять туннель после перезагрузки Mac без приложения.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `TunnelLibrary` | порт `TunnelSecretStore`, `TunnelIdentifier`, `TunnelStorageError` |
| Системные фреймворки | Foundation | JSON сообщений |
| Сторонние библиотеки | нет | |

## Принцип работы

- **Требование к клиенту.** `ClientCodeRequirement(teamIdentifier:bundleIdentifier:)` строит строку для `setCodeSigningRequirement` XPC-слушателя расширения: `anchor apple generic and certificate leaf[subject.OU] = "<Team ID>" and identifier "<bundle ID>"`. Подключиться может только приложение нашей команды. Team ID — ровно 10 заглавных латинских букв или цифр. Bundle ID — сегменты из букв, цифр и дефиса через одну точку. Кавычки, пробелы и пустые сегменты отклоняются, поэтому в язык требований нельзя подставить своё условие.
- **Сообщения.** `SecretDeliveryMessage`: `.store(tunnel:configurationText:)` и `.remove(tunnel:)`. Ответ `SecretDeliveryReply` — `.done` или `.failed(SecretDeliveryFailure)` (`storageUnavailable`, `malformedMessage`, `unsupportedSchemaVersion`). `description`, `debugDescription` и `Mirror` сообщения не показывают текст конфигурации.
- **Кодек.** `SecretDeliveryCodec` кодирует сообщения и ответы в JSON-конверт со `schemaVersion` (сейчас 1). Сначала читается версия, и чужая версия — `unsupportedSchemaVersion`. Нехватка полей или не тот вид сообщения — `malformed`.
- **Приложение.**
  - `MirroredTunnelSecretStore` реализует `TunnelSecretStore`: читает и пишет свою копию (Keychain пользователя) и после каждой записи или удаления передаёт то же самое в расширение через порт `ExtensionSecretChannel`.
  - Недоступное расширение (ещё не одобрено, переустанавливается) не ломает сохранение: ошибка уходит в `reportDeliveryFailure`, то есть в журнал.
  - `DeliverTunnelSecretUseCase` перед активацией туннеля отправляет расширению текущую копию. Если отправить не вышло, активация получает ошибку (`extensionUnreachable`, `secretUnavailable`, `rejected`).
- **Расширение.** `SecretDeliveryRequestHandler(store:)` разбирает запрос, применяет его к своему `TunnelSecretStore` (в расширении это будет System Keychain) и отвечает. Неразборчивый запрос и чужая версия получают отказ, а не тишину.

## Публичный API

`ClientCodeRequirement`, `ClientCodeRequirementError`, `SecretDeliveryMessage`, `SecretDeliveryReply`, `SecretDeliveryFailure`, `SecretDeliveryError`, `SecretDeliveryCodec`, `SecretDeliveryCodingError`; порт `ExtensionSecretChannel`; сценарии `MirroredTunnelSecretStore`, `DeliverTunnelSecretUseCase`, `SecretDeliveryRequestHandler`. В `SecretDeliveryTestSupport` — `LoopbackExtensionSecretChannel`: настоящие кодек и обработчик в памяти, с отключаемой доступностью.

## Решения

- Своя копия в Keychain пользователя остаётся источником истины. Копия расширения — производная, её обновляют каждое сохранение и каждая активация.
- Сообщения — один `Data`-конверт с версией, а не набор методов `@objc`-протокола XPC. Протокол меняется без смены интерфейса XPC, а старое расширение честно отвечает `unsupportedSchemaVersion`.
- Ответ проверяет `requireSuccess()` из Core, поэтому XPC-адаптер и петлевой фейк ведут себя одинаково.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Ошибка доставки при сохранении не ломает сохранение | Откатить сохранение | Расширение может быть ещё не одобрено. Пользователь не должен терять правку, а активация всё равно отправит свежую копию | Нет |
| Требование `anchor apple generic` + Team ID + identifier | Только Team ID; точное `designated requirement` сборки | Подходят и сборки разработки, и Developer ID, а чужая команда и другое приложение нашей команды отклоняются | Если появятся другие клиенты XPC |
| Вариант B до спайка SP-5 | Ждать SP-5 | Кодек, требование и сценарии не зависят от транспорта и останутся при варианте A. Меняется только адаптер | По итогам SP-5 |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- XPC-клиент и слушатель (`NSXPCConnection` по `NEMachServiceName`) и `SystemKeychainSecretStore` появятся после спайка SP-5. Проверить их можно только с подписанным системным расширением.
- Текст конфигурации внутри конверта передаётся открытым: защиту даёт требование к подписи клиента XPC, а не шифрование сообщения.

## Тесты

21 тест в `SecretDeliveryTests`:

- требование к клиенту: строка для нашей команды и приложения, отказ для неверного Team ID (длина, регистр, кавычки, пробелы) и bundle ID, который мог бы изменить требование;
- кодек: сообщения и ответы туда и обратно, чужая версия схемы, неразборчивые данные, текст конфигурации не виден в описаниях;
- зеркало: запись в обе копии, сохранение без расширения с отчётом об ошибке, удаление из обеих копий, чтение только своей копии, сценарий «изменили туннель → копия в расширении обновлена» через `CreateTunnelUseCase` и `UpdateTunnelUseCase`;
- доставка перед активацией: текущая копия, недоступное расширение, нет своей копии, расширение не смогло сохранить;
- обработчик расширения: сохранение, удаление, неразборчивый запрос и чужая версия, сбой хранилища.

Запуск: `swift test --package-path Packages/SplitwayKit --filter SecretDelivery`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-30 | Требование к клиенту XPC, сообщения и кодек, зеркальная копия, доставка перед активацией, обработчик расширения | M2-12 |
