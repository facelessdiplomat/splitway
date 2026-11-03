# Тестовая ВМ macOS

Mac-версию с системным расширением проверяем в виртуальной машине macOS 26 на Mac разработчика (решение D-32 в [журнале решений](../../docs/00-decisions.md)). Туннель в ВМ не трогает сеть хоста, проверки не забирают курсор, а между проверками ВМ возвращается к чистому состоянию.

## Что нужно

- [Tart](https://github.com/cirruslabs/tart) 2.32 или новее, команда `tart` в `PATH`. Формула Homebrew `cirruslabs/cli/tart` не ставится на текущий Homebrew, поэтому Tart ставится из релиза GitHub: архив `tart.tar.gz` с проверкой контрольной суммы из формулы, подписи и нотаризации Cirrus Labs (`spctl --assess`). Лицензия Fair Source не ограничивает использование на Mac одного человека.
- Около 30 ГБ на диске для образа `ghcr.io/cirruslabs/macos-tahoe-base` (macOS 26.6 с гостевым агентом Tart). Скрипт закрепляет образ по дайджесту.
- ВМ зарегистрирована в Apple Developer как устройство **macOS**. Её идентификатор — 40 шестнадцатеричных цифр, как у старых iPhone, поэтому в форме регистрации легко оставить платформу iOS. Тогда ВМ попадает в профили iOS, а не Mac, и AMFI не запускает приложение: «Code has restricted entitlements, but the validation of its code signature failed».
- Xcode не добавляет новое устройство в уже выданный профиль Xcode Managed. После регистрации ВМ профили `Mac Team Provisioning Profile: com.facelessdiplomat.splitway` и `…network-extension` убираются из `~/Library/Developer/Xcode/UserData/Provisioning Profiles`: следующая сборка с `-allowProvisioningUpdates` получает новые профили со всеми устройствами Mac.

## Первый запуск

1. `Scripts/macos-vm.sh create` — скачать образ и создать ВМ `splitway-macos26`.
2. `Scripts/macos-vm.sh start --headless`, затем `Scripts/macos-vm.sh device-id` — идентификатор ВМ для регистрации.
3. Владелец регистрирует ВМ: developer.apple.com → Devices → «+» → macOS.
4. `Scripts/macos-vm.sh stop` и `Scripts/macos-vm.sh start` — ВМ с окном.
5. `Scripts/macos-vm.sh install` — сборка разработки с новым номером сборки, установка в `/Applications` ВМ.
6. `Scripts/macos-vm.sh launch -Splitway.hasCompletedOnboarding YES` — приложение без онбординга сразу запрашивает активацию расширения.
7. Владелец в окне ВМ одобряет расширение (System Settings → General → Login Items & Extensions → Network Extensions), затем подключает любой туннель: «Before you connect» → Continue → «Splitway Would Like to Add VPN Configurations» → Allow. Пароль пользователя ВМ — `admin`, как во всех образах Cirrus Labs. Для туннеля подходит конфиг со случайными ключами и адресом из TEST-NET: подключение упадёт, а одобрение останется.
8. `Scripts/macos-vm.sh exec sudo -n /usr/sbin/networksetup -setMTU Ethernet 1280` — MTU 1280 для сети ВМ. Если хост выходит в интернет через свой VPN с меньшим MTU, пакеты ВМ в 1500 байт пропадают по пути: TCP соединяется, а TLS зависает.
9. Разрешить гостевому агенту управлять System Events: `Scripts/macos-vm.sh exec osascript -e 'tell application "System Events" to count processes'` вызывает запрос «tart-guest-agent wants access to control System Events», владелец нажимает Allow. После этого `osascript` через `exec` нажимает кнопки и переключатели в ВМ без владельца.
10. `Scripts/macos-vm.sh save-clean-state` — выключить ВМ изнутри и сохранить диск с одобрениями.

## Проверка

```bash
Scripts/macos-vm.sh restore-clean-state
Scripts/macos-vm.sh start --headless
Scripts/macos-vm.sh install
Scripts/macos-vm.sh launch -Splitway.hasCompletedOnboarding YES
Scripts/macos-vm.sh exec systemextensionsctl list
```

- Новая сборка расширения встаёт без вопросов: `sysextd` пишет «replacing extension … with inherited user approval».
- `install <рабочая копия>` собирает приложение из другой рабочей копии, например ветки спайка.
- Журнал ВМ читается через `exec`, например `Scripts/macos-vm.sh exec log show --last 5m --predicate 'process == "sysextd"'`.
- `Scripts/macos-vm.sh screenshot <файл>` сохраняет снимок экрана ВМ: так видно окна приложения и системные запросы.
- `Scripts/macos-vm.sh leak-test <сценарий>` ставит в ВМ утилиту RoutingProbe и запускает там тесты утечек ([Scripts/RoutingProbe](../RoutingProbe/README.md)).
- `Scripts/macos-vm.sh relay-benchmark <метка>` так же запускает в ВМ замеры ретрансляции (`Scripts/relay-benchmark-macos.sh`).
- Тестовый конфиг попадает в ВМ потоком, минуя репозиторий: `tart exec -i splitway-macos26 /bin/sh -c 'umask 077; cat > "$HOME/Desktop/cz-prg.conf"' < "$SPLITWAY_TEST_TUNNEL_CONFIG"`. После проверки ВМ возвращается к чистому состоянию: удалённый файл остался бы в свободных блоках диска, а чистое состояние ключа не видело.
- После перезагрузки ВМ macOS сама открывает приложение без аргументов. Чтобы передать аргументы, приложение сначала закрывают: `Scripts/macos-vm.sh exec pkill -x Splitway`.

## Как это устроено

- Команды в ВМ выполняет гостевой агент Tart (`tart exec`), без SSH и паролей; `sudo` в образе работает без пароля.
- Папка `build/macos-vm/shared` подключена в ВМ только для чтения как `/Volumes/My Shared Files/splitway`. Каждая установка кладёт сборку в новую папку `install-<номер сборки>`: гость кэширует содержимое общей папки, и бандл, заменённый на месте, виден ему пустым.
- Каждая установка получает новый номер сборки (`CURRENT_PROJECT_VERSION`): приложение не заменяет работающее расширение той же версии (`ExtensionReplacementPolicy`).
- После копирования в общую папку `install` снимает регистрацию сборки в LaunchServices хоста: её номер больше, чем у установленного Splitway, и по bundle ID macOS открыла бы её.
- `stop` выключает macOS изнутри (`/sbin/shutdown`) и только через две минуты останавливает ВМ принудительно: `tart stop` сразу обрывает работу гостя, и диск, сохранённый после него, может не получить последние записи.
- Чистое состояние — APFS-копии `disk.img` и `nvram.bin` в `~/.tart/clean-states/<ВМ>`. Конфигурация ВМ с её идентификатором устройства не меняется, поэтому регистрация и профили остаются в силе.

## Ограничения

- ВМ не заменяет настоящий Mac для замеров скорости (SP-3, M4-16), смены Wi-Fi и Ethernet, сна и пробуждения, выводов спайков и проверки перед выпуском.
- В образе Cirrus Labs выключен SIP: `sysextd` не проверяет подпись расширения (`requirement string is "always"`). Проверку подписи и одобрения на машине с SIP даёт только настоящий Mac.
- Один ключ тестового туннеля — одно устройство одновременно (см. [Тестовый туннель](../test-tunnel/README.md)): проверки в ВМ и на iPhone с одним конфигом идут по очереди.
