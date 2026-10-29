# M2. Движок и режим «Весь трафик»

Цель: туннель из библиотеки запускается и останавливается из кода приложения на iOS и macOS; приложение видит статус, статистику и причину ошибки. Интерфейс пока минимальный (отладочная кнопка в оболочке приложения).

## Статус

- [x] M2-01 Кодирование UAPI и разбор статистики
- [x] M2-02 Мост Go: API режима fd
- [x] M2-03 `fdtunnel`: wireguard-go поверх utun
- [x] M2-04 Swift-адаптер `TunnelCoreAdapter` (режим fd)
- [x] M2-05 План сетевых настроек
- [x] M2-06 Инфраструктура пакетного туннеля
- [x] M2-07 Протокол сообщений «приложение ↔ расширение»
- [ ] M2-08 Сборка расширений
- [x] M2-09 Домен и сценарии подключения
- [ ] M2-10 Системный слот пакетного туннеля — код и тесты готовы, проверка на устройстве ждёт M0-04
- [ ] M2-11 Установка системного расширения
- [ ] M2-12 Передача секретов в системное расширение
- [ ] M2-13 Журнал в расширении и движке
- [ ] M2-14 Сквозная проверка «Весь трафик»
- [ ] M2-15 Документы фич M2

## TunnelEngine

### M2-01. Кодирование UAPI и разбор статистики
`shared` · M · зависит от: M1-06

**Сделать:** в `TunnelEngine` Core: `UAPIConfigurationEncoder` (`TunnelConfiguration` + `ResolvedEndpoint` по публичным ключам пиров → `UAPIConfiguration`, текст которого не виден в `description`, `debugDescription` и `Mirror`): `private_key` в hex, `listen_port`, `replace_peers=true`, `public_key`, `preshared_key`, `endpoint` только для разрезолвленных пиров, `persistent_keepalive_interval`, `replace_allowed_ips=true`, `allowed_ip` без битов хоста. `UAPIRuntimeStatisticsParser` → `RuntimeStatistics` (на каждого пира `rx_bytes`, `tx_bytes`, `last_handshake_time_sec/nsec`; суммы и последнее рукопожатие); `errno` ≠ 0 → `UAPIResponseError.deviceError`. Порты `WireGuardDeviceEngine` и `RunningWireGuardDevice` (режим fd). Порт `UserspaceNetworkEngine` (режим netstack) объявляется в M4-06 вместе с реализацией, чтобы не угадывать его API заранее.
**Тесты сначала:** snapshot UAPI для фикстур `full` и `multiplePeers`; endpoint без резолвинга не пишется; `allowed_ip` без битов хоста; текст UAPI не виден ни в одном текстовом представлении; разбор ответа `get=1` в формате wireguard-go с двумя пирами; отсутствие рукопожатия (`0`) → `nil`; `errno`; повреждённые ответы.
**Готово, когда:** UAPI принимается настоящим wireguard-go в Go-тесте M2-03.

### M2-02. Мост Go: API режима fd
`shared` · M · зависит от: M0-08

**Сделать:** в пакете `bridge`: таблица хэндлов `tunnelRegistry` (Go-указатели не уходят в C; хэндлы — положительные `int32`, занятый хэндл повторно не выдаётся), `tc_fd_tunnel_start`, `tc_tunnel_update_config`, `tc_tunnel_get_config` (строку освобождает вызывающий через `tc_free`), `tc_tunnel_bump_sockets`, `tc_tunnel_stop`, `tc_set_log_callback` (обратный вызов приходит из любых потоков движка). Коды `TCStatus` и уровни `TCLogLevel` — закрытые перечисления в `TunnelCoreTypes.h`. Go берёт их значения из того же заголовка через cgo, поэтому разойтись они не могут. Экспортные функции только преобразуют типы; логика написана на обычном Go и тестируется без C.
**Тесты сначала:** Go-тесты на `tuntest`: разные положительные хэндлы, двойная остановка, операции с неизвестным хэндлом, отклонённая конфигурация без хэндла, недоступный интерфейс, применение и чтение конфигурации, перепривязка сокетов; `goleak`.
**Готово, когда:** API стабильно и описано в заголовке `TunnelCore.h`.

### M2-03. `fdtunnel`: wireguard-go поверх utun
`shared` · M · зависит от: M2-02

**Сделать:** пакет `fdtunnel`. `StartOnFileDescriptor` дублирует дескриптор utun (`unix.Dup`, неблокирующий режим) и создаёт устройство через `tun.CreateTUNFromFile`; `Start` работает поверх любого `tun.Device` (`conn.NewDefaultBind`, `IpcSet`, `Up`). Методы `Apply`, `Configuration`, `BumpSockets`, `Stop`; ошибки `ErrTunnelInterfaceUnavailable`, `ErrConfigurationRejected`, `ErrDeviceUnavailable`. Для iOS — `debug.SetMemoryLimit` (30 МБ, файл с тегом `ios`); уменьшенные очереди дают константы wireguard-go для `GOOS=ios`. Пакет `logbridge`: `DeviceLogger` передаёт `Verbosef` и `Errorf` wireguard-go в приёмник вместе с уровнем. wireguard-go закреплён на коммите `b3bc704` (2026-10-25): в нём и предыдущем коммите исправления рукопожатия и разбора пакетов.
**Тесты сначала:** два устройства на `tuntest`, соединённые через loopback: рукопожатие и доставка ping; wireguard-go принимает `testdata/full.uapi` — с этим же файлом Swift-тест M2-01 сверяет вывод кодировщика; неверная конфигурация, дескриптор не utun, закрытый дескриптор; перепривязка сокетов; уровни логов; `goleak.VerifyTestMain`.
**Готово, когда:** Go-тесты проходят, утечек горутин нет (`goleak`).

### M2-04. Swift-адаптер `TunnelCoreAdapter` (режим fd)
`shared` · M · зависит от: M2-01, M2-03

**Сделать:** `TunnelCoreWireGuardEngine` реализует `WireGuardDeviceEngine`, а `TunnelCoreWireGuardDevice` — `RunningWireGuardDevice`: устройство владеет хэндлом и останавливает туннель в `deinit`; коды `TCStatus` преобразуются в `TunnelEngineError` (добавлен случай `socketsUnavailable`); строка `tc_tunnel_get_config` освобождается через `tc_free` и разбирается `UAPIRuntimeStatisticsParser`. `TunnelCoreLogRouting.route(to:)` направляет логи wireguard-go в `LogRecorder` (verbose → `debug`, error → `error`); направления хранятся до конца процесса, поэтому обратный вызов из Go никогда не видит освобождённый контекст. Пакет `TunnelCore` зависит от `SplitwayKit` (продукты `TunnelEngine` и `Diagnostics`).
**Тесты сначала:** интеграционные на настоящем Go-ядре: закрытый дескриптор и файл, который не utun, → `tunnelInterfaceUnavailable`, а дескриптор вызывающего остаётся открытым; таблица соответствия всех `TCStatus` доменным ошибкам. Отступление: успешный старт, конфигурацию и статистику на macOS без root проверить нельзя — utun создаётся только привилегированным процессом, поэтому этот путь проверяется на устройстве в M2-08.
**Готово, когда:** адаптер не допускает утечек: хэндл освобождается в `deinit`, C-строки — в `defer`; проверка в Instruments — вместе с M2-08.

## PacketTunnel

### M2-05. План сетевых настроек
`shared` · M · зависит от: M1-09, M1-10

**Сделать:** фича `PacketTunnel` (Core). `TunnelNetworkPlanner.plan(for:routedBy:)` → `TunnelNetworkPlan`: адреса и маршруты по семействам (`TunnelAddressFamilyPlan`), DNS (`TunnelDNSPlan`: серверы, домены поиска, `scope = .allDomains`, то есть `matchDomains = [""]`; без серверов — `nil`, DNS остаётся системным), MTU (`.fixed` из конфига или `.pathMTUWithOverhead(bytes: 80)`). Маршруты — объединение `AllowedIPs` всех пиров и подсетей адресов интерфейса через `IPNetworkSet`: перекрытия сливаются, «исключить локальные сети» уже учтено в `AllowedIPs`. IPv6 — по решению D-30 (`IPv6LeakProtection`): туннель, который забирает весь публичный IPv4, но не `2000::/3`, получает этот маршрут, а если у интерфейса нет IPv6 — адрес-заглушку из ULA `fdc6:3a2b:91e4::1/128`. Режимы выбора приложений и сервисов → `routingModeNotSupported` (их планы строятся в M4 и M5); маршруты IPv4 без адреса IPv4 → `missingInterfaceAddress(.ipv4)`. В SharedKernel добавлены `IPNetwork(host:)` и `IPNetwork.ipv6GlobalUnicast`.
**Тесты сначала:** только IPv4 с блокировкой утечек IPv6; IPv4+IPv6; IPv6 маршрутизируется частично; несколько пиров с пересекающимися `AllowedIPs` (у туннеля по частям IPv6 не трогается); исключение локальных сетей; DNS с доменами поиска; без DNS; MTU; неподдерживаемый режим; маршруты IPv4 без адреса IPv4.
**Готово, когда:** план полностью определяется конфигом и политикой и не зависит от NetworkExtension.

### M2-06. Инфраструктура пакетного туннеля
`shared` · L · зависит от: M2-04, M2-05

**Сделать:** Core: `PacketTunnelSession` (actor) над портами `WireGuardDeviceEngine`, `TunnelNetworkSettingsApplier`, `TunnelInterfaceLocator`, `EndpointResolver` и `NetworkPathMonitor`. Старт: план → резолвинг endpoint всех пиров (любой нерезолвящийся → `endpointUnresolvable`) → сетевые настройки → дескриптор utun → устройство; `stop()` во время старта прерывает его до запуска устройства (`cancelled`). Возврат сети (`available`): повторный резолвинг (неудачные endpoint пропускаются), новая конфигурация UAPI и `bumpSockets`; пропажа сети — ожидание. Пробуждение — `bumpSockets`. Статистика работающего устройства, иначе `notRunning`. Infrastructure: `NetworkSettingsMapper` (план → `NEPacketTunnelNetworkSettings`: адреса и маски, маршруты, DNS с `matchDomains = [""]`, MTU или `tunnelOverheadBytes`), `PacketTunnelSettingsApplier` (actor над `setTunnelNetworkSettings`), `UtunDescriptorLocator` (перебор дескрипторов 0…1024 с `UTUN_OPT_IFNAME`), `SystemEndpointResolver` (`getaddrinfo` с `AI_DEFAULT` на отдельной очереди GCD — блокирующий вызов не занимает кооперативный пул; синтез NAT64; IPv4 предпочтительнее), `NetworkPathObserver` (`NWPathMonitor`).
**Тесты сначала:** `PacketTunnelSession` с фейками: порядок шагов старта; повторный резолвинг и перепривязка при возврате сети (endpoint NAT64); пропажа сети; остановка во время старта; нерезолвящийся endpoint, отклонённые настройки, нет utun, ошибка движка; пробуждение; остановка; статистика. Маппер — сравнение полей для двухстекового плана и для плана без IPv6, DNS и MTU; резолвер — адресные литералы и `localhost` без сети; локатор — процесс без utun.
**Готово, когда:** логика сессии покрыта тестами; провайдер только делегирует сессии (связывание — M2-08).

## ProviderMessaging

### M2-07. Протокол сообщений «приложение ↔ расширение»
`shared` · M · зависит от: M2-01

**Сделать:** фича `ProviderMessaging`. Конверт `{ protocolVersion, payload }` для запросов и ответов: после обновления приложения может работать старое расширение, поэтому версия есть в обоих направлениях. `ProviderRequest` (`runtimeStatistics`, `applyRoutingPolicy(policy:)`, `healthCheck`), `ProviderResponse` (`runtimeStatistics(statistics:)`, `routingPolicyApplied`, `health(isTunnelRunning:)`, `failure(reason:)`), `ProviderFailure`. `ProviderMessageCodec` (JSON) сначала читает версию, чужая версия → `unsupportedProtocolVersion(found:)`, любые повреждения → `malformedMessage`. `ProviderMessageDispatcher` в расширении превращает любые байты в ответ: чужую версию и мусор — в явный `failure`. Порты `ProviderMessenger` (приложение) и `ProviderMessageHandler` (расширение); адаптер `TunnelProviderSessionMessenger` — actor над `NETunnelProviderSession.sendProviderMessage`, отвечает `incompatibleExtension(protocolVersion:)` при чужой версии. `RuntimeStatistics` стал `Codable` (ключи пиров — base64).
**Тесты сначала:** round-trip всех запросов и ответов; чужая версия → явная ошибка в запросе и ответе; шесть видов повреждённых данных и неверный ключ пира → ошибка без падения; диспетчер передаёт запрос обработчику, а на чужую версию и мусор отвечает явным `failure`, не вызывая обработчик.
**Готово, когда:** кодек покрыт тестами, адаптеры тонкие. У слоя Infrastructure тестов нет по построению (`layersWithoutTests` в `Package.swift`): адаптер только вызывает NetworkExtension.

### M2-08. Сборка расширений
`iOS+iPadOS`, `macOS` · M · зависит от: M1-13, M1-14, M2-06, M2-07

**Сделать:** composition root в `Apps/PacketTunnelExtension` и `Apps/NetworkSystemExtension` (`PacketTunnelProvider`): чтение id активного туннеля из `providerConfiguration`, загрузка конфига (iOS — Keychain; macOS — хранилище из M2-12), запуск сессии, обработка сообщений, `cancelTunnelWithError` с доменной ошибкой и запись последней ошибки в App Group.
**Тесты сначала:** не требуются (связывание без логики; логика покрыта в M2-06 и M2-07).
**Готово, когда:** тестовый туннель поднимается на iPhone и macOS через временную отладочную кнопку.

## TunnelConnection

### M2-09. Домен и сценарии подключения
`shared` · M · зависит от: M1-12

**Сделать:** фича `TunnelConnection` (Core). `ConnectionState` (`disconnected`, `connecting`, `connected(since:)`, `reasserting`, `disconnecting`, `failed(ConnectionFailure)`). `ConnectionStateMachine` превращает `SystemConnectionStatus` в состояние: неожиданное завершение сессии → `failed` с причиной из `lastDisconnectFailure()` (её запрашивают, только когда сессия завершилась), отказ держится до следующей попытки, ненастроенный слот → `disconnected`. `ConnectionCoordinator` выполняет намерения пользователя по одному через асинхронную FIFO-очередь. Каждое намерение получает номер на акторе вызывающего (`nonisolated(nonsending)`), устаревшее пропускает оставшиеся шаги — побеждает последнее действие. Активация: тот же туннель уже подключается или подключён → ничего не делать; активен другой → остановить его; записать слот; запустить. Сценарии `ActivateTunnelUseCase`, `DeactivateTunnelUseCase`, `ObserveConnectionStateUseCase` (`AsyncStream`), `FetchRuntimeStatisticsUseCase` (через `ProviderMessenger`; причины недоступности — `RuntimeStatisticsError`). Порт `SystemTunnelController`. `ConnectionActivityProbe` реализует `TunnelActivityProbe` для `TunnelLibrary`.
**Тесты сначала:** активация в свободном слоте; при активном другом туннеле (сначала остановка); повторное нажатие во время `connecting`; повторная установка того же неактивного туннеля; ошибка сохранения слота без запуска; деактивация; гонки: «активировать A, активировать B, отключить» → только уже начатая установка A и остановка; «A, затем B» → запущен B (15 повторов без расхождений); состояния сессии, причина неожиданного отключения, отказ до следующей попытки, ненастроенный слот; статистика и шесть причин её недоступности; проба активности.
**Готово, когда:** гонки при быстрых переключениях разрешаются детерминированно (последнее действие пользователя выигрывает).

### M2-10. Системный слот пакетного туннеля
`shared` · M · зависит от: M2-09

**Сделать:** `PacketTunnelSlotController` в `TunnelConnectionInfrastructure` (actor, реализует `SystemTunnelController`). Находит сохранённый `NETunnelProviderManager` по `providerBundleIdentifier` или создаёт новый; задаёт `NETunnelProviderProtocol` с `serverAddress` — endpoint первого пира или имя туннеля (`TunnelSlotDescription`) — и `providerConfiguration` = `TunnelProviderConfiguration` (id туннеля и снимок политики, без секретов, с версией в общем конверте); имя слота «Splitway» (D-17); включает, сохраняет и перечитывает настройки. `startVPNTunnel` / `stopVPNTunnel`: остановка ждёт отключения (событие или 10 с). Поток статусов из `NEVPNStatusDidChange` — только для своего соединения; `fetchLastDisconnectError`. Контракт приложения и расширения лежит в `ProviderMessaging`: `TunnelProviderConfigurationCodec` и `TunnelStopReason` (код `NSError` в домене `Splitway.TunnelStop`, который расширение передаёт в `cancelTunnelWithError`). `ConnectionFailure(stopReason:)` объясняет причину отключения; `VPNErrorMapping`: `configurationReadWriteFailed` при сохранении → `permissionDenied` (пользователь не разрешил VPN), остальные ошибки → `systemConfigurationUnavailable`.
**Тесты сначала:** `VPNStatusMapping` (все `NEVPNStatus`, дата подключения по умолчанию), `VPNErrorMapping`, кодек `providerConfiguration` (round-trip, нет данных, чужая версия, мусор), `TunnelStopReason` через `NSError`, `ConnectionFailure(stopReason:)`, адрес сервера в системных настройках. Сам контроллер — тонкая обёртка над NetworkExtension.
**Готово, когда:** подключение и отключение работают из кода, статус приходит в приложение. Проверка на устройстве ждёт подписи (M0-04) и проходит вместе с M2-14.

## macOS: SystemExtension и секреты

### M2-11. Установка системного расширения
`macOS` · M · зависит от: M0-06

**Сделать:** `SystemExtension` Core: `SystemExtensionState`, политика замены по `CFBundleVersion`, `EnsureSystemExtensionActivatedUseCase`. Infrastructure: `OSSystemExtensionActivator` (делегат `OSSystemExtensionRequest`, обработка `needsUserApproval`, `willCompleteAfterReboot`, ошибок).
**Тесты сначала:** переходы состояний; решение о замене (новая версия, та же, старая).
**Готово, когда:** расширение устанавливается на чистой системе и корректно заменяется при обновлении приложения.

### M2-12. Передача секретов в системное расширение
`macOS` · L · зависит от: SP-5, M1-14, M2-11

**Сделать:** вариант, выбранный в SP-5 (по умолчанию — B): XPC-протокол `SecretDeliveryService` через `NEMachServiceName`; сервер в расширении с проверкой подписи клиента (`setCodeSigningRequirement`, только наш Team ID и bundle ID); `SystemKeychainSecretStore` в расширении; `SystemExtensionSecretStore` в приложении (отправляет копию при сохранении, изменении и активации; удаляет при удалении туннеля).
**Тесты сначала:** построитель строки code signing requirement; кодек XPC-сообщений; сценарий «изменили туннель → копия обновлена» на фейках.
**Готово, когда:** расширение запускает туннель после перезагрузки Mac без участия приложения, а приватный ключ не лежит ни в одном plist.

## Диагностика и проверка

### M2-13. Журнал в расширении и движке
`shared` · S · зависит от: M1-18, M2-04

**Сделать:** подключить `LogRecorder` с `RotatingFileLogStore` (директория в App Group) и `OSLogWriter` в расширениях; логи wireguard-go проходят маскирование до записи.
**Тесты сначала:** тест, что строка лога движка с ключом записывается замаскированной.
**Готово, когда:** журнал расширения виден в файле App Group и в Console.app, ключей в нём нет.

### M2-14. Сквозная проверка «Весь трафик»
`iOS+iPadOS`, `macOS` · M · зависит от: M2-08, M2-10, M2-12

**Сделать:** ручной прогон по чек-листу: рукопожатие; внешний IP = IP сервера; DNS через туннель; статистика растёт; смена Wi-Fi ↔ сотовая (iOS) и Wi-Fi ↔ Ethernet (macOS); сон и пробуждение; отключение из системных настроек; невалидный ключ → понятная ошибка.
**Тесты сначала:** не требуются (ручная проверка; результаты в документе фичи).
**Готово, когда:** все пункты чек-листа пройдены на iPhone, iPad и Mac.

### M2-15. Документы фич M2
`shared` · S · зависит от: M2-01…M2-14

**Сделать:** `docs/features/TunnelEngine.md`, `PacketTunnel.md`, `ProviderMessaging.md`, `TunnelConnection.md`, `SystemExtension.md`.
**Тесты сначала:** не требуются.
**Готово, когда:** в документах описаны C API, выбор способа хранения секретов на macOS и правила гонок при подключении.
