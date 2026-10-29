# ProviderMessaging

| | |
|---|---|
| Статус | завершена для M2 |
| Платформы | shared |
| Задачи | M2-07, M2-10 (конфигурация слота, причины остановки) |
| Таргеты | `ProviderMessaging`, `ProviderMessagingInfrastructure` |

## Назначение

Контракт между приложением и расширением:

- сообщения `sendProviderMessage` / `handleAppMessage`;
- содержимое `providerConfiguration` системного слота;
- коды причины, по которой туннель остановился.

После обновления приложения может ещё работать старое расширение, поэтому у всего контракта есть версия.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `TunnelEngine`, `AppRouting`, `TunnelLibrary` | статистика, политика, id туннеля |
| Системные фреймворки | Foundation, NetworkExtension (адаптер) | JSON, `NSError`; `NETunnelProviderSession` |
| Сторонние библиотеки | нет | |

## Принцип работы

- **Конверт.** Сообщения и конфигурация слота упаковываются в `{ "protocolVersion": N, "payload": … }` общим `VersionedEnvelopeCoder`. Он сначала читает версию: чужая версия даёт явную ошибку, а не неверно прочитанные данные.
- **Сообщения.** `ProviderRequest`: `runtimeStatistics`, `applyRoutingPolicy(policy:)`, `healthCheck`. `ProviderResponse`: `runtimeStatistics(statistics:)`, `routingPolicyApplied`, `health(isTunnelRunning:)`, `failure(reason:)`.
- **Сторона расширения.** `ProviderMessageDispatcher` превращает любые байты в ответ. Чужую версию он отвечает `failure(.unsupportedProtocolVersion)`, мусор — `failure(.malformedRequest)`, и обработчик при этом не вызывается.
- **Сторона приложения.** `TunnelProviderSessionMessenger` (actor над `NETunnelProviderSession`) кодирует запрос и декодирует ответ. Чужая версия ответа становится `incompatibleExtension(protocolVersion:)`.
- **Слот.** `TunnelProviderConfigurationCodec` хранит в `providerConfiguration` только `TunnelProviderConfiguration` (id туннеля и снимок политики) под ключом `SplitwayTunnel`. Секретов там нет.
- **Причина остановки.** `TunnelStopReason` — код `NSError` в домене `Splitway.TunnelStop`. Расширение передаёт его в `cancelTunnelWithError`, а приложение читает через `fetchLastDisconnectError`.

## Публичный API

`ProviderRequest`, `ProviderResponse`, `ProviderFailure`, `ProviderMessageCodec`, `ProviderMessageCodingError`, `ProviderMessageDispatcher`, `ProviderMessageHandler`, `ProviderMessenger`, `ProviderMessagingError`, `TunnelProviderConfiguration`, `TunnelProviderConfigurationCodec`, `TunnelProviderConfigurationError`, `TunnelStopReason`; адаптер `TunnelProviderSessionMessenger`.

## Решения

- Версия есть в обоих направлениях: старое расширение должно уметь сказать «я старое».
- `RuntimeStatistics` кодируется с ключами пиров в base64.
- У слоя Infrastructure нет тестов по построению (`layersWithoutTests`): адаптер только вызывает NetworkExtension.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Синтезированный `Codable` перечислений в JSON | Свои ключи и ручное кодирование | Короче и проверено round-trip тестами; оба конца собираются из одного кода | При первом несовместимом изменении сообщений — тогда растёт `protocolVersion` |
| Конфигурация слота использует тот же конверт с ключом `protocolVersion` | Отдельный формат с `schemaVersion` | Один механизм версий для всего контракта приложения и расширения | Нет |
| Причина остановки передаётся числом в `NSError` | Файл в App Group; сообщение перед остановкой | `cancelTunnelWithError` и `fetchLastDisconnectError` — штатный канал системы, работает и после завершения процесса расширения | Нет |
| `TunnelProviderSessionMessenger` — actor | Структура с `@unchecked Sendable` | `NETunnelProviderSession` не `Sendable`; actor получает её через `sending` | Если Apple пометит сессию как `Sendable` |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- `sendProviderMessage` не ограничен по времени: если расширение не вызовет обработчик ответа, запрос будет ждать. Таймаут добавляется вместе с экраном статистики (M3).
- Поддерживается только точное совпадение версий.

## Тесты

14 тестов в `ProviderMessagingTests`:

- round-trip всех запросов и ответов;
- чужая версия в запросе и ответе;
- шесть видов повреждённых данных и неверный ключ пира;
- диспетчер;
- конфигурация слота (round-trip, нет данных, чужая версия, мусор);
- `TunnelStopReason` через `NSError`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-29 | Протокол сообщений, диспетчер, адаптер приложения | M2-07 |
| 2026-10-29 | Конфигурация слота, причины остановки, общий конверт | M2-10 |
