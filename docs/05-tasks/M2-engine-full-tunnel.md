# M2. Движок и режим «Весь трафик»

Цель: туннель из библиотеки запускается и останавливается из кода приложения на iOS и macOS; приложение видит статус, статистику и причину ошибки. Интерфейс пока минимальный (отладочная кнопка в оболочке приложения).

## Статус

- [x] M2-01 Кодирование UAPI и разбор статистики
- [x] M2-02 Мост Go: API режима fd
- [x] M2-03 `fdtunnel`: wireguard-go поверх utun
- [x] M2-04 Swift-адаптер `TunnelCoreAdapter` (режим fd)
- [ ] M2-05 План сетевых настроек
- [ ] M2-06 Инфраструктура пакетного туннеля
- [x] M2-07 Протокол сообщений «приложение ↔ расширение»
- [ ] M2-08 Сборка расширений
- [ ] M2-09 Домен и сценарии подключения
- [ ] M2-10 Системный слот пакетного туннеля
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

**Сделать:** в `PacketTunnel` Core: `TunnelNetworkPlan` — адреса IPv4/IPv6, включённые маршруты из `AllowedIPs` всех пиров (с учётом «исключить локальные сети»), DNS-серверы и домены поиска (`matchDomains = [""]` для полного туннеля), MTU (из конфига или `tunnelOverheadBytes = 80`). Поведение IPv6 у туннелей только с IPv4 — по решению D-30.
**Тесты сначала:** табличные тесты: только IPv4; IPv4+IPv6; несколько пиров с пересекающимися `AllowedIPs`; без DNS; с исключением локальных сетей.
**Готово, когда:** план полностью определяется конфигом и политикой и не зависит от NetworkExtension.

### M2-06. Инфраструктура пакетного туннеля
`shared` · L · зависит от: M2-04, M2-05

**Сделать:** `NetworkSettingsMapper` (план → `NEPacketTunnelNetworkSettings`), `UtunDescriptorLocator`, `SystemEndpointResolver` (`getaddrinfo`, синтез NAT64), `NetworkPathObserver` (`NWPathMonitor`), `PacketTunnelSession`: старт, стоп, смена сети (повторный резолвинг + `bump_sockets`), сон и пробуждение. Класс провайдера в `Apps/*` только делегирует сессии.
**Тесты сначала:** `PacketTunnelSession` с фейковыми портами: порядок шагов старта; повторный резолвинг при смене пути; остановка во время старта. Маппер проверяется тестом на сравнение полей.
**Готово, когда:** логика сессии покрыта тестами, провайдер содержит только вызовы сессии.

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

**Сделать:** `ConnectionState` (`disconnected`, `connecting`, `connected(since:)`, `reasserting`, `disconnecting`, `failed(ConnectionFailure)`), правила перехода; `ActivateTunnelUseCase` (активный туннель только один: остановить другой, записать системный слот, запустить), `DeactivateTunnelUseCase`, `ObserveConnectionStateUseCase` (`AsyncStream`), `FetchRuntimeStatisticsUseCase`. Порт `SystemTunnelController`. Реализация порта `TunnelActivityProbe` для `TunnelLibrary`.
**Тесты сначала:** активация при уже активном другом туннеле; повторное нажатие во время `connecting`; ошибка сохранения слота; отображение причины последнего отключения.
**Готово, когда:** гонки при быстрых переключениях разрешаются детерминированно (последнее действие пользователя выигрывает).

### M2-10. Системный слот пакетного туннеля
`shared` · M · зависит от: M2-09

**Сделать:** `PacketTunnelSlotController` (реализует `SystemTunnelController`): найти или создать `NETunnelProviderManager`, задать `NETunnelProviderProtocol` (`providerBundleIdentifier`, `serverAddress` — endpoint для отображения, `providerConfiguration` с id туннеля и снимком политики), включить, сохранить, `startVPNTunnel` / `stopVPNTunnel`, поток статусов из `NEVPNStatusDidChange`, `fetchLastDisconnectError`.
**Тесты сначала:** маппинг `NEVPNStatus` → `ConnectionState` и построение `providerConfiguration` выносятся в чистые функции и тестируются.
**Готово, когда:** подключение и отключение работают из кода, статус приходит в приложение.

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
