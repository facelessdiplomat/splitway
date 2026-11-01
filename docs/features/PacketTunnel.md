# PacketTunnel

| | |
|---|---|
| Статус | в работе: туннель поднимается на iPhone (M2-14) и в системном расширении macOS (M2-12); на Mac пройдены все пункты M2-14 — в тестовой ВМ (2026-10-31) и на Mac владельца (сон и смена Wi-Fi, 2026-11-01); журнал расширения на iPhone проверен (M2-13); остальные проверки M2-14 — на iPhone и iPad |
| Платформы | shared |
| Задачи | M2-05, M2-06, M2-08, M2-13, M4-08 (`IPv6LeakProtection.applying(to:)`) |
| Таргеты | `PacketTunnel`, `PacketTunnelInfrastructure`; провайдер и composition root `Apps/SharedTunnelProvider` — общие для расширения iOS (`Apps/PacketTunnelExtension`) и системного расширения macOS (`Apps/NetworkSystemExtension`) |

## Назначение

Пакетный туннель режима «Весь трафик». Фича строит сетевые настройки из конфигурации и политики и запускает движок на дескрипторе utun. Она переживает смену сети и сон, отвечает приложению на сообщения и сообщает, почему туннель остановился.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | `TunnelConfiguration`, `AppRouting`, `TunnelEngine`, `TunnelLibrary`, `ProviderMessaging`, `SharedKernel` | конфигурация, политика, движок, секреты, контракт с приложением, сети |
| Системные фреймворки | NetworkExtension, Network, Darwin | настройки туннеля, `NWPathMonitor`, `getaddrinfo` и `getsockopt` |
| Сторонние библиотеки | нет | |

## Принцип работы

```mermaid
sequenceDiagram
  participant P as PacketTunnelProvider
  participant L as LoadActiveTunnelUseCase
  participant S as PacketTunnelSession
  P->>L: providerConfiguration
  L-->>P: ActiveTunnel (конфиг из Keychain, политика)
  P->>S: prepareStart
  S-->>P: PreparedTunnelStart (план, endpoint)
  P->>P: setTunnelNetworkSettings(план)
  P->>S: completeStart
  S->>S: utun → движок → наблюдение за сетью
```

1. **План.** `TunnelNetworkPlanner` строит `TunnelNetworkPlan`:
   - адреса и маршруты по семействам — объединение `AllowedIPs` всех пиров и подсетей адресов интерфейса;
   - DNS: `matchDomains = [""]`, без серверов DNS остаётся системным;
   - MTU из конфига или `tunnelOverheadBytes = 80`.
2. **IPv6 (решение D-30).** `IPv6LeakProtection` добавляет `2000::/3` туннелю, который забирает весь публичный IPv4, но не весь глобальный IPv6. Если у интерфейса нет IPv6, он получает адрес-заглушку ULA `fdc6:3a2b:91e4::1/128`. wireguard-go отбрасывает такие пакеты, потому что их не принимает ни один пир. То же правило `IPv6LeakProtection.applying(to:)` использует план прозрачного прокси (`TransparentProxy`).
3. **Старт сессии.** `PacketTunnelSession` (actor) проходит шаги:
   - `prepareStart`: план и резолвинг всех endpoint;
   - `setTunnelNetworkSettings` выполняет провайдер;
   - `completeStart`: дескриптор utun через `UtunDescriptorLocator`, запуск устройства, наблюдение за сетью.

   `stop()` в любой момент старта прерывает его до запуска устройства (`cancelled`).
4. **Смена сети и сон.** Когда сеть возвращается, сессия заново резолвит endpoint (NAT64 мог измениться), применяет только `public_key` и `endpoint` пиров (`UAPIConfigurationEncoder.endpointUpdate`) и вызывает `bumpSockets`. Пиры не пересоздаются, поэтому их сеансы и рукопожатия сохраняются: монитор сети присылает состояние и сразу после старта, и полная конфигурация с `replace_peers=true` сбрасывала бы пира каждый раз (найдено на iPhone 2026-10-30). Пробуждение тоже вызывает `bumpSockets`.
5. **Резолвинг.** `ResolveTunnelEndpointsUseCase` резолвит endpoint-ы всех пиров: `allEndpoints(of:)` при старте (любая неудача — `EndpointResolutionError`) и `reachableEndpoints(of:)` при смене сети (пиры без ответа пропускаются). Им же пользуется сессия прозрачного прокси (`TransparentProxy`). `SystemEndpointResolver` вызывает `getaddrinfo` с `AI_DEFAULT` на отдельной очереди GCD, чтобы блокирующий вызов не занимал кооперативный пул. iOS синтезирует NAT64-адрес, IPv4 предпочтительнее.
6. **Ответы приложению.** `PacketTunnelMessageHandler` отдаёт статистику, `health(isTunnelRunning:)` и принимает только политику «Весь трафик».
7. **Причина остановки.** Ошибки старта превращаются в `TunnelStopReason(packetTunnelError:)` и уходят в `cancelTunnelWithError`.
8. **Две платформы.** `PacketTunnelProvider` и `PacketTunnelComposition` лежат в `Apps/SharedTunnelProvider` и собираются в оба расширения. Отличается только хранилище секретов: на iOS — `KeychainTunnelSecretStore` с общей группой Keychain, на macOS — `SystemKeychainSecretStore` (фича `SecretDelivery`): системное расширение работает от root и получает конфигурацию по XPC (решение D-33). Песочнице расширения macOS нужны права `com.apple.security.network.client` и `network.server`, иначе wireguard-go не откроет сокет маршрутизации и UDP-сокет.

## Публичный API

`TunnelNetworkPlanner`, `TunnelNetworkPlan`, `TunnelAddressFamilyPlan`, `TunnelDNSPlan`, `TunnelDNSScope`, `TunnelMTU`, `TunnelNetworkPlanError`, `IPv6LeakProtection`, `PacketTunnelSession`, `PreparedTunnelStart`, `PacketTunnelError`, `LoadActiveTunnelUseCase`, `ActiveTunnel`, `ResolveTunnelEndpointsUseCase`, `PacketTunnelMessageHandler`, порты `EndpointResolver`, `TunnelInterfaceLocator`, `NetworkPathMonitor`, `NetworkPathStatus`; адаптеры `NetworkSettingsMapper`, `SystemEndpointResolver`, `UtunDescriptorLocator`, `NetworkPathObserver`.

## Решения

- Режимы выбора приложений и сервисов дают `routingModeNotSupported`: их планы строятся в M4 и M5.
- Маршруты IPv4 без адреса IPv4 — ошибка плана `missingInterfaceAddress(.ipv4)`, а не непонятный отказ NetworkExtension.
- Последнюю ошибку приложение получает через `fetchLastDisconnectError` (минимальная ОС 26), поэтому файл ошибки в App Group не нужен.
- Журнал расширения и движка пишется в `Library/Logs/Splitway` контейнера App Group. Идентификатор группы задаёт ключ `SplitwayAppGroupIdentifier` в Info.plist.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Старт сессии разделён на `prepareStart` и `completeStart`, настройки применяет провайдер | Порт `TunnelNetworkSettingsApplier` в сессии | `NEPacketTunnelProvider` не `Sendable` и не может попасть в другой домен изоляции без `@unchecked Sendable`, а правила это запрещают. Порядок и отмена остались в сессии | Если Apple пометит провайдер как `Sendable` |
| Блокировка IPv6 — маршрут `2000::/3`, а не `::/0` | `::/0` | ULA и link-local остаются локальными, принтеры и NAS в сети продолжают работать | Если появятся утечки через не-глобальный IPv6 |
| Пакеты заблокированного IPv6 отбрасываются молча | Ответ ICMPv6 unreachable | Отбрасывание не требует обработки пакетов; адрес ULA отодвигает IPv6 в выборе адреса (RFC 6724), и приложения сразу идут на IPv4 | Если задержки соединений станут заметны |
| `tunnelRemoteAddress = 127.0.0.1` | Endpoint первого пира | У туннеля может быть несколько пиров; адрес для системных настроек задаёт `serverAddress` слота (M2-10) | Нет |
| Симулятор собирается только для arm64 | Слайс ядра x86_64 для симулятора | Xcode 27 работает только на Apple silicon, лишний слайс удлинил бы сборку Go | Нет |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- Журнал системного расширения macOS пишется в контейнер App Group пользователя root, и экран журнала приложения его пока не показывает; системный журнал (`log show`) видит обе стороны.
- На реальном устройстве проверяются старт, смена Wi-Fi и сотовой сети, NAT64 и журнал в App Group (M2-14).
- Ошибки повторного резолвинга и `bumpSockets` при смене сети пока не пишутся в журнал.

## Тесты

- 32 теста в `PacketTunnelTests`:
  - планировщик сетевых настроек (одиннадцать сценариев, включая IPv6 по D-30);
  - сессия: порядок старта, смена сети с NAT64, пропажа сети, остановка во время старта и между шагами, ошибки резолвинга, utun и движка, пробуждение, статистика, `isRunning`;
  - загрузка активного туннеля;
  - причины остановки;
  - обработчик сообщений.
- 8 тестов в `PacketTunnelInfrastructureTests`: поля `NEPacketTunnelNetworkSettings`, резолвинг адресных литералов и `localhost` без сети, процесс без utun.

- Живой UI-тест `LiveTunnelTests` на iPhone (`Scripts/live-tunnel-test.sh <устройство>`): подключает импортированный тестовый туннель, сравнивает внешний адрес без туннеля и через него (`api.ipify.org` через эфемерную `URLSession` процесса теста, сами адреса не печатаются) и отключает туннель. Прошёл 2026-10-30 и 2026-10-31 на iPhone 13 Pro. Журнал этой сессии: рукопожатие есть, после старта пир ни разу не пересоздавался.

Composition root по правилам не тестируется.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-29 | План сетевых настроек, блокировка утечек IPv6 | M2-05 |
| 2026-10-29 | Сессия и системные адаптеры | M2-06 |
| 2026-10-29 | Расширение iOS, разделённый старт, загрузка активного туннеля | M2-08 |
| 2026-10-29 | Журнал расширения и движка | M2-13 |
| 2026-10-30 | При смене сети обновляются только endpoint-ы, сеансы пиров сохраняются | M2-06 |
| 2026-10-30 | `IPv6LeakProtection.applying(to:)` для плана прозрачного прокси | M4-08 |
| 2026-10-30 | Общий провайдер для iOS и системного расширения macOS, секреты из System Keychain, права на сеть в песочнице macOS | M2-12 |
| 2026-10-30 | Резолвинг endpoint-ов вынесен в `ResolveTunnelEndpointsUseCase`, общий с прозрачным прокси | M4-11 |
| 2026-10-31 | Живой тест читает внешний адрес через `URLSession`, а не в Safari: возврат из Safari в приложение съедал нажатие на переключатель, а Safari мог показать прежний адрес до загрузки страницы | M2-14 |
| 2026-11-01 | Сон и смена Wi-Fi на Mac владельца: на Mac пройдены все пункты M2-14 | M2-14 |
