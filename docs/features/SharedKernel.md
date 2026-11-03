# SharedKernel

| | |
|---|---|
| Статус | изменена: сеть одного адреса и диапазон `2000::/3` (M2-05), `Ticker` (M3-12), байты адреса и `AwaitableState` (M4-10) |
| Платформы | macOS |
| Задачи | M0-05, M1-01, M1-02, M1-03, M1-05, M2-05 (сети для полного туннеля), M3-12 (`Ticker`), M4-10 (байты адреса, `AwaitableState`), M7-02 (`AbandonedExportCopies`) |
| Таргеты | `SharedKernel`, `SharedKernelTestSupport` |

## Назначение

Общие value objects, на которых построены остальные фичи: IP-адреса и сети CIDR с алгеброй множеств, сетевой порт, доменное имя, строгий разбор десятичных чисел, часы и периодические тики. Все типы неизменяемые, `Sendable` и проверяют инварианты при создании.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | нет | общее ядро, от него зависят все фичи |
| Системные фреймворки | Foundation, Synchronization | `Date`, `Codable`, `CharacterSet`; `Mutex` в `ManualTicker` |
| Сторонние библиотеки | нет | |

## Принцип работы

- `IPAddress` хранит семейство и значение `UInt128`; адрес IPv4 лежит в младших 32 битах. Разбор выполняют собственные `IPv4AddressParser` и `IPv6AddressParser`: октеты IPv4 строго десятичные и без ведущих нулей, IPv6 поддерживает `::` и встроенный IPv4, зоны `%en0` отклоняются. IPv6 форматируется по RFC 5952. Адреса сравниваются сначала по семейству, затем по значению; `Codable` — строкой. `networkOrderBytes` и `init?(networkOrderBytes:)` переводят адрес в 4 или 16 байт в сетевом порядке и обратно: так адаптеры NetworkExtension и Network обходятся без форматирования строк.
- `IPNetwork` — адрес и длина префикса с проверкой диапазона. `normalized` обнуляет биты хоста, `hasHostBits` сообщает об их наличии; есть `contains`, `overlaps`, `firstAddress` и `lastAddress`. Известные диапазоны (`loopbackNetworks`, `linkLocalNetworks`, `privateNetworks`, `multicastNetworks`, `reservedNetworks`, маршруты по умолчанию, глобальный IPv6 `ipv6GlobalUnicast` = `2000::/3` для решения D-30) объявлены как сети. `IPNetwork(host:)` — сеть ровно из одного адреса. Классификация адресов (`isLoopback`, `isLinkLocal`, `isPrivate`, `isMulticast`) выражена через эти сети, а `isUnspecified` узнаёт `0.0.0.0` и `::`.
- `IPNetworkSet` держит по одному `AddressRanges` на семейство: отсортированные непересекающиеся `ClosedRange<UInt128>`, соседние диапазоны сливаются при создании. Объединение, пересечение и вычитание — линейные проходы по двум отсортированным спискам. `networks` раскладывает диапазоны в минимальный список CIDR (`CIDRDecomposition`).
- `NetworkPort` — 1…65535, `Codable` числом. `DomainName` — ASCII и punycode, метка до 63 символов, имя до 253, нижний регистр, завершающая точка отбрасывается; `isSameOrSubdomain(of:)` сравнивает по суффиксу меток.
- `CanonicalDecimalText` — единое строгое правило для чисел из конфигураций: только цифры, без знака, пробелов и ведущих нулей; `integerValue` принимает до 9 цифр.
- `WallClock` и `SystemWallClock` — источник времени для сценариев. В `SharedKernelTestSupport` есть `FixedWallClock` и `SeededRandomNumberGenerator` (SplitMix64) для воспроизводимых property-тестов.
- `AwaitableState` в `SharedKernelTestSupport` — состояние фейка за `Mutex`, которого тест может дождаться (`wait(until:)`): так проверяются асинхронные насосы без задержек и опроса.
- `Ticker` — поток тиков для периодической работы моделей (опрос статистики, обновление журнала). `RepeatingTicker` даёт первый тик сразу, затем раз в заданный интервал, пока поток не отменят. `ManualTicker` в `SharedKernelTestSupport` даёт тики по команде теста и сообщает, идёт ли подписка, а `ManualWallClock` там же — часы, которые тест передвигает сам.

- `AbandonedExportCopies` — порт удаления копий экспорта, который закончился без сохранения: SwiftUI `fileExporter` пишет файл во временную папку заранее и после отмены его не убирает. Порт общий для экспорта туннелей и журнала, реализация `TemporaryExportCopies` лежит в `TunnelLibraryInfrastructure`, а связывает их composition root. Фейк `RecordingAbandonedExportCopies` в `SharedKernelTestSupport` запоминает содержимое, которое просили удалить.

## Публичный API

`IPAddress`, `IPAddressFamily`, `IPAddressParsingError`, `IPNetwork` (с `init(host:)` и `ipv6GlobalUnicast`), `IPNetworkParsingError`, `IPNetworkSet`, `NetworkPort`, `NetworkPortValidationError`, `DomainName`, `DomainNameValidationError`, `CanonicalDecimalText`, `WallClock`, `SystemWallClock`, `Ticker`, `RepeatingTicker`, `AbandonedExportCopies`.

## Решения

- Адрес внутри — число `UInt128`, а не строка или массив байтов: сравнение, маски и диапазоны сводятся к арифметике без аллокаций.
- Множество сетей построено на диапазонах, а не на дереве префиксов: операции над `AllowedIPs` и списками исключений — слияние отсортированных массивов.
- Классификация адресов перенесена из M1-01 в M1-02, потому что естественно выражается через известные сети.
- `Ticker` переехал из `TunnelLibraryPresentation` в M3-12: его используют две фичи, статистика туннеля и журнал.

## Спорные решения

| Решение | Альтернативы | Почему так | Когда пересмотреть |
|---|---|---|---|
| Собственный разбор адресов без `inet_pton` | `inet_pton`, `Network.IPv4Address` | Одинаково строгие правила (ведущие нули, зоны) на всех платформах и в тестах, без C-строк и без `Network` в Core | Если в Foundation появится строгий переносимый парсер |
| Имя `IPAddress` совпадает с протоколом `Network.IPAddress` | `IPAddressValue`, `InternetAddress` | Самое понятное имя. `Network` нужен только инфраструктуре, там тип квалифицируется как `SharedKernel.IPAddress` | Если конфликт начнёт мешать в большинстве адаптеров |
| `NetworkPort` вместо `Port` | `Port` | `Foundation.Port` — существующий класс, конфликт при любом `import Foundation` | Нет |
| `WallClock` вместо `Clock` | `Clock`, `DateProvider` | `Swift.Clock` — протокол стандартной библиотеки с другим смыслом (монотонное время) | Нет |
| `DomainName` принимает только ASCII и punycode | Преобразование Unicode в punycode (IDNA) | IDNA тянет таблицы Unicode, а домены в конфигах WireGuard и каталоге сервисов — ASCII | Если пользователи начнут вводить IDN в «свои сервисы» (M5) |

## Отступления от правил разработки

Нет.

## Ограничения и известные проблемы

- `DomainName` не преобразует IDN: имя на кириллице отклоняется ошибкой.
- `CanonicalDecimalText.integerValue` ограничен 9 цифрами. Этого хватает для портов, MTU, интервалов и длин префиксов.
- `RepeatingTicker` не покрыт тестами: он только повторяет `Task.sleep`, а тесты по правилам идут без ожиданий. Модели проверяются с `ManualTicker`.

## Тесты

78 тестов в `SharedKernelTests`:

- табличные тесты разбора и форматирования адресов, включая IPv4-mapped IPv6 и отклонение зон;
- такие же тесты для сетей, портов и доменов, сеть одного адреса, маршруты по умолчанию и глобальный диапазон IPv6;
- алгебра `IPNetworkSet` с эталоном «`0.0.0.0/0` минус частные сети»;
- property-тест «объединение разности и вычитаемого равно исходному множеству» на случайных сетях с фиксированным seed;
- байты адреса в сетевом порядке туда и обратно, отказ для длины не IPv4 и не IPv6;
- классификация адресов, включая неопределённые `0.0.0.0` и `::`;
- часы.

Запуск: `swift test --package-path Packages/SplitwayKit --filter SharedKernelTests`.

## История изменений

| Дата | Изменение | Задача |
|---|---|---|
| 2026-10-29 | Часы `WallClock` | M0-05 |
| 2026-10-29 | `IPAddress` | M1-01 |
| 2026-10-29 | `IPNetwork`, `IPNetworkSet`, классификация адресов | M1-02 |
| 2026-10-29 | `NetworkPort`, `DomainName` | M1-03 |
| 2026-10-29 | `CanonicalDecimalText` стал публичным | M1-05 |
| 2026-10-29 | `IPNetwork(host:)`, `ipv6GlobalUnicast` | M2-05 |
| 2026-10-29 | `Ticker`, `RepeatingTicker`, `ManualTicker` из `TunnelLibraryPresentation` | M3-12 |
| 2026-10-30 | `IPAddress.networkOrderBytes`, `AwaitableState` | M4-10 |
| 2026-10-30 | `IPAddress.isUnspecified` | M4-11 |
| 2026-10-31 | `ManualWallClock` в `SharedKernelTestSupport` | M4-15 |
| 2026-11-02 | Порт `AbandonedExportCopies` и фейк `RecordingAbandonedExportCopies` переехали из `TunnelLibrary` | M7-02 |
