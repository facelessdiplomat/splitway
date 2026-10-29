# SharedKernel

| | |
|---|---|
| Статус | завершена (M1) |
| Платформы | shared |
| Задачи | M0-05, M1-01, M1-02, M1-03, M1-05 |
| Таргеты | `SharedKernel`, `SharedKernelTestSupport` |

## Назначение

Общие value objects, на которых построены остальные фичи: IP-адреса и сети CIDR с алгеброй множеств, сетевой порт, доменное имя, строгий разбор десятичных чисел и часы. Все типы неизменяемые, `Sendable` и проверяют инварианты при создании.

## Зависимости

| Тип | Что | Зачем |
|---|---|---|
| Фичи проекта | нет | общее ядро, от него зависят все фичи |
| Системные фреймворки | Foundation | `Date`, `Codable`, `CharacterSet` |
| Сторонние библиотеки | нет | |

## Принцип работы

- `IPAddress` хранит семейство и значение `UInt128`; адрес IPv4 лежит в младших 32 битах. Разбор выполняют собственные `IPv4AddressParser` и `IPv6AddressParser`: октеты IPv4 строго десятичные и без ведущих нулей, IPv6 поддерживает `::` и встроенный IPv4, зоны `%en0` отклоняются. IPv6 форматируется по RFC 5952. Адреса сравниваются сначала по семейству, затем по значению; `Codable` — строкой.
- `IPNetwork` — адрес и длина префикса с проверкой диапазона. `normalized` обнуляет биты хоста, `hasHostBits` сообщает об их наличии; есть `contains`, `overlaps`, `firstAddress` и `lastAddress`. Известные диапазоны (`loopbackNetworks`, `linkLocalNetworks`, `privateNetworks`, `multicastNetworks`, `reservedNetworks`, маршруты по умолчанию) объявлены как сети. Классификация адресов (`isLoopback`, `isLinkLocal`, `isPrivate`, `isMulticast`) выражена через эти сети.
- `IPNetworkSet` держит по одному `AddressRanges` на семейство: отсортированные непересекающиеся `ClosedRange<UInt128>`, соседние диапазоны сливаются при создании. Объединение, пересечение и вычитание — линейные проходы по двум отсортированным спискам. `networks` раскладывает диапазоны в минимальный список CIDR (`CIDRDecomposition`).
- `NetworkPort` — 1…65535, `Codable` числом. `DomainName` — ASCII и punycode, метка до 63 символов, имя до 253, нижний регистр, завершающая точка отбрасывается; `isSameOrSubdomain(of:)` сравнивает по суффиксу меток.
- `CanonicalDecimalText` — единое строгое правило для чисел из конфигураций: только цифры, без знака, пробелов и ведущих нулей; `integerValue` принимает до 9 цифр.
- `WallClock` и `SystemWallClock` — источник времени для сценариев. В `SharedKernelTestSupport` есть `FixedWallClock` и `SeededRandomNumberGenerator` (SplitMix64) для воспроизводимых property-тестов.

## Публичный API

`IPAddress`, `IPAddressFamily`, `IPAddressParsingError`, `IPNetwork`, `IPNetworkParsingError`, `IPNetworkSet`, `NetworkPort`, `NetworkPortValidationError`, `DomainName`, `DomainNameValidationError`, `CanonicalDecimalText`, `WallClock`, `SystemWallClock`.

## Решения

- Адрес внутри — число `UInt128`, а не строка или массив байтов: сравнение, маски и диапазоны сводятся к арифметике без аллокаций.
- Множество сетей построено на диапазонах, а не на дереве префиксов: операции над `AllowedIPs` и списками исключений — слияние отсортированных массивов.
- Классификация адресов перенесена из M1-01 в M1-02, потому что естественно выражается через известные сети.

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

## Тесты

73 теста в `SharedKernelTests`:

- табличные тесты разбора и форматирования адресов, включая IPv4-mapped IPv6 и отклонение зон;
- такие же тесты для сетей, портов и доменов;
- алгебра `IPNetworkSet` с эталоном «`0.0.0.0/0` минус частные сети»;
- property-тест «объединение разности и вычитаемого равно исходному множеству» на случайных сетях с фиксированным seed;
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
