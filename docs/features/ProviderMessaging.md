# ProviderMessaging

| | |
|---|---|
| Статус | завершена для M2 |
| Платформы | macOS |
| Задачи | M2-07, M2-10 (конфигурация слота, причины остановки), M3-03 (ограничение ожидания ответа), M5-07 (обработчик в контексте провайдера) |
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
- **Сторона расширения.** `ProviderMessageDispatcher` превращает любые байты в ответ. Чужую версию он отвечает `failure(.unsupportedProtocolVersion)`, мусор — `failure(.malformedRequest)`, и обработчик при этом не вызывается. Диспетчер обобщён по обработчику, а `ProviderMessageHandler.handle` — `nonisolated(nonsending)`: оба выполняются в контексте `handleAppMessage` провайдера. Поэтому обработчик может держать зависимости, которые не `Sendable`, например сам провайдер для `setTunnelNetworkSettings` ([PacketTunnel](PacketTunnel.md)). Диспетчер `Sendable`, если `Sendable` его обработчик: прозрачный прокси хранит его в своей композиции.
- **Сторона приложения.** `TunnelProviderSessionMessenger` (actor над `NETunnelProviderSession`) кодирует запрос и декодирует ответ. Чужая версия ответа становится `incompatibleExtension(protocolVersion:)`. Ответ ждётся не дольше 3 с, после этого запрос завершается `noResponse`. `PendingProviderReply` пропускает только первый исход: ответ расширения или истечение срока.
- **Слот.** `TunnelProviderConfigurationCodec` хранит в `providerConfiguration` только `TunnelProviderConfiguration` (id туннеля и снимок политики) под ключом `SplitwayTunnel`. Секретов там нет.
- **Причина остановки.** `TunnelStopReason` — код `NSError` в домене `Splitway.TunnelStop`. Расширение передаёт его в `cancelTunnelWithError`, а приложение читает через `fetchLastDisconnectError`.

## Публичный API

`ProviderRequest`, `ProviderResponse`, `ProviderFailure`, `ProviderMessageCodec`, `ProviderMessageCodingError`, `ProviderMessageDispatcher`, `ProviderMessageHandler`, `ProviderMessenger`, `ProviderMessagingError`, `TunnelProviderConfiguration`, `TunnelProviderConfigurationCodec`, `TunnelProviderConfigurationError`, `TunnelStopReason`; адаптер `TunnelProviderSessionMessenger`.

## Решения

- Версия есть в обоих направлениях: старое расширение должно уметь сказать «я старое».
- `RuntimeStatistics` кодируется с ключами пиров в base64.
- Тесты слоя Infrastructure проверяют только `PendingProviderReply`: остальное в адаптере — вызовы NetworkExtension.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Синтезированный `Codable` перечислений в JSON | Свои ключи и ручное кодирование | Короче и проверено round-trip тестами; оба конца собираются из одного кода | При первом несовместимом изменении сообщений — тогда растёт `protocolVersion` |
| Конфигурация слота использует тот же конверт с ключом `protocolVersion` | Отдельный формат с `schemaVersion` | Один механизм версий для всего контракта приложения и расширения | Нет |
| Причина остановки передаётся числом в `NSError` | Файл в App Group; сообщение перед остановкой | `cancelTunnelWithError` и `fetchLastDisconnectError` — штатный канал системы, работает и после завершения процесса расширения | Нет |
| `TunnelProviderSessionMessenger` — actor | Структура с `@unchecked Sendable` | `NETunnelProviderSession` не `Sendable`; actor получает её через `sending` | Если Apple пометит сессию как `Sendable` |
| Обработчик сообщений не обязан быть `Sendable` и выполняется в контексте вызывающего | Обработчик `Sendable`, а провайдер — за `@unchecked Sendable` | Пакетному туннелю нужен `setTunnelNetworkSettings` провайдера, а `NEPacketTunnelProvider` не `Sendable`. В контексте `handleAppMessage` провайдер никуда не передаётся | Если Apple пометит провайдер как `Sendable` |
| Срок ожидания ответа — 3 с | Без срока; срок у каждого сценария | Экран статистики опрашивает расширение раз в секунду, и зависший запрос не должен останавливать опрос навсегда. Один срок для всех сообщений проще, а сообщения короткие | Если появятся долгие запросы |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- Запрос, на который расширение не ответило, отменить раньше 3 с нельзя: `sendProviderMessage` не поддерживает отмену.
- Поддерживается только точное совпадение версий.

## Тесты

14 тестов в `ProviderMessagingTests`:

- round-trip всех запросов и ответов;
- чужая версия в запросе и ответе;
- шесть видов повреждённых данных и неверный ключ пира;
- диспетчер;
- конфигурация слота (round-trip, нет данных, чужая версия, мусор);
- `TunnelStopReason` через `NSError`.

- 2 теста в `ProviderMessagingInfrastructureTests`: `PendingProviderReply` пропускает только первый исход, будь то ответ или ошибка.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-29 | Протокол сообщений, диспетчер, адаптер приложения | M2-07 |
| 2026-10-29 | Конфигурация слота, причины остановки, общий конверт | M2-10 |
| 2026-10-29 | Срок ожидания ответа расширения | M3-03 |
| 2026-11-01 | Диспетчер обобщён по обработчику, обработчик выполняется в контексте провайдера | M5-07 |
