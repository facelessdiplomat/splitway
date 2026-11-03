# CI

CI — GitHub Actions (решение D-47). Тяжёлые задания идут на собственном раннере на Mac владельца: там есть Xcode с SDK macOS 26, сертификат Developer ID и профиль нотаризации. На этот раннер попадают только доверенные события — пуши в `master`, теги выпусков и ручной запуск. Код из чужих PR на нём не выполняется. Хук `pre-merge-commit` с `Scripts/check.sh` остаётся: CI повторяет проверку, а не заменяет её.

## Workflow

| Файл | Когда | Где | Что делает |
|---|---|---|---|
| `check.yml` | пуш в `master`, ручной запуск | раннер `splitway` | `Scripts/check.sh` |
| `release.yml` | тег `v*` | раннер `splitway` | `Scripts/release.sh <версия> --publish`: DMG с подписью Developer ID и нотаризацией в GitHub Releases ([03-platform-macos.md](03-platform-macos.md), раздел 9) |
| `pull-request.yml` | pull request | облачный `macos-latest` | `gofmt`, проверка комментариев Go, `go vet` и `go test` всех Go-модулей; секретов и раннера владельца не видит |
| `site.yml` | пуш в `master` с изменениями в `Site/`, ручной запуск | облачный `ubuntu-latest` | публикует `Site/` на GitHub Pages ([site.md](site.md)); пока репозиторий приватный, задание пропускается |

Комментариев в YAML нет, как и в остальном коде (правила разработки, раздел 1).

## Раннер

- Где: `~/actions-runner/splitway`, учётная запись владельца, служба `launchd` `actions.runner.facelessdiplomat-splitway.splitway-mac` (`~/Library/LaunchAgents`). Агент работает в сеансе владельца, пока тот вошёл в систему, и задания видят его связку ключей с сертификатом Developer ID и профилем `splitway-notary`. Для этого в plist службы нет ключа `SessionCreate`. Шаблон `svc.sh` его добавляет, и тогда задания идут в отдельном сеансе безопасности, где `notarytool` не находит профиль: так 2026-11-03 упал первый запуск выпуска 1.0.
- Имя `splitway-mac`, метки `self-hosted`, `macOS`, `ARM64`, `splitway`. Workflow выбирают раннер по метке `splitway`.
- Версия: v2.338.2 из [actions/runner](https://github.com/actions/runner/releases), контрольная сумма архива сверена с описанием релиза. Раннер обновляется сам.
- Состояние: `~/actions-runner/splitway/svc.sh status`; журналы — `~/Library/Logs/actions.runner.facelessdiplomat-splitway.splitway-mac`.
- Переустановка: `./svc.sh stop && ./svc.sh uninstall`, затем `./config.sh remove --token <токен>` и регистрация заново с токеном из `gh api -X POST repos/facelessdiplomat/splitway/actions/runners/registration-token --jq .token`. После `./svc.sh install` ключ `SessionCreate` убирают снова: `plutil -remove SessionCreate` для plist службы, затем `launchctl bootout gui/$(id -u)/actions.runner.facelessdiplomat-splitway.splitway-mac` и `launchctl bootstrap gui/$(id -u)` с тем же plist.
- В журналах заданий публичного репозитория видны имя раннера и имя компьютера (`Machine name`) — сетевое имя Mac, которое печатает `hostname`. Другое имя задаёт `sudo scutil --set HostName <имя>`, после чего службу перезапускают.
- Сборки раннера лежат в `build.noindex`: `check.sh` и `release.sh` сами делают `build` ссылкой на эту папку (`Scripts/lib/build-directory.sh`), как `bootstrap.sh` в рабочей копии. Иначе Spotlight индексирует сборки в `_work`, и macOS показывает их среди приложений: 2026-11-03 вместо `/Applications/Splitway.app` так открылась неподписанная отладочная сборка из `check.sh`.
- Xcode регистрирует в LaunchServices каждое собранное приложение. Номер сборки у копии из `release.sh` такой же, как у установленного выпуска, а у сборки для ВМ больше, и по bundle ID («Команды», Siri, `open -b`) macOS открыла бы их вместо `/Applications/Splitway.app`. Поэтому `release.sh` при выходе и `macos-vm.sh install` после копирования снимают регистрацию своих сборок (`Scripts/lib/launch-services.sh`).

## Настройки репозитория

После открытия репозитория (M8-06): workflow из PR внешних участников запускаются только после одобрения владельца (Settings → Actions → General → «Require approval for all external contributors»), GitHub Pages публикует из GitHub Actions, включены закрытые сообщения об уязвимостях.
