# SP-8. Запуск VPN из контрола без открытия приложения

| | |
|---|---|
| Статус | в симуляторе iPhone 18 Pro (iOS 27.2) 2026-11-01: intent контрола выполняется в расширении виджетов. Запуск туннеля из расширения на iPhone, в том числе с экрана блокировки, проверяется в M6-04 |
| Вопрос | В каком процессе выполняется `perform()` интента контрола и можно ли оттуда управлять VPN-конфигурацией без открытия приложения ([04-platform-ios-ipados.md](../../04-platform-ios-ipados.md), разделы 8 и 10) |
| Код | ветка `spike/SP-8`, в `master` не сливается; рабочий код — фича [ControlWidgets](../ControlWidgets.md) |
| Вывод | **Intent выполняется в процессе расширения виджетов, а не в приложении**, даже когда его тип собран и в приложение. Расширение само загружает `NETunnelProviderManager` и запускает туннель, для этого ему нужны те же entitlements, что пакетному туннелю. Открывать приложение (`openAppWhenRun`) не нужно |

## Как проверяли

- Ветка `spike/SP-8`: widget extension `ControlsExtension` с `ControlWidgetToggle`. Его `SetValueIntent` собран и в приложение, и в расширение.
- `perform()` и `currentValue()` пишут в файл App Group имя процесса, bundle ID и ответ `NETunnelProviderManager.loadAllFromPreferences()`.
- Расширение получило entitlement Network Extension (`packet-tunnel-provider`), App Group и группу Keychain, как пакетный туннель. Такой же набор у VPN-клиента NetBird, который подключает туннель из своего контрола ([netbirdio/ios-client](https://github.com/netbirdio/ios-client), `NetBirdWidgetExtension`).
- Симулятор iPhone 18 Pro, iOS 27.2:
  - контрол добавлен в Пункт управления и нажат;
  - Пункт управления закрыт и открыт снова.

## Результаты

| Проверка | Результат |
|---|---|
| Процесс `perform()` | `ControlsExtension` (`com.facelessdiplomat.splitway.controls`), хотя intent собран в оба таргета |
| Процесс `currentValue()` | `ControlsExtension` |
| `NETunnelProviderManager` в расширении | в симуляторе `NEVPNErrorDomain` 5 «IPC failed»: VPN в симуляторе недоступен |
| После `perform()` | система сама перечитывает значение контрола |
| Повторное открытие Пункта управления | `currentValue()` не вызывается: система показывает сохранённое значение |
| Галерея контролов | после первой установки контрола в галерее не было, хотя `chronod` его проиндексировал. После перезагрузки симулятора он появился, а следующие установки перезагрузки не требовали |
| Запуск туннеля из расширения на iPhone | проверяется в M6-04 ([ControlWidgets](../ControlWidgets.md)) |

## Вывод

- Intent контрола выполняется в расширении. Приложение не запускается, поэтому расширение само читает библиотеку туннелей, записывает туннель в слот VPN и запускает его.
- Расширению нужны Network Extension, App Group и группа Keychain: без Keychain не прочитать конфигурацию туннеля, который ещё не записан в слот.
- Значение контрола система хранит у себя. Когда статус туннеля меняется не через контрол, обновление нужно запросить явно: `ControlCenter.shared.reloadControls(ofKind:)`.
