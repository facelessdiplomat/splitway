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

- Где: `~/actions-runner/splitway`, учётная запись владельца, служба `launchd` `actions.runner.facelessdiplomat-splitway.splitway-mac` (`~/Library/LaunchAgents`). Агент работает, пока владелец вошёл в систему, поэтому ему доступны связка ключей входа с сертификатом Developer ID и профилем `splitway-notary`.
- Имя `splitway-mac`, метки `self-hosted`, `macOS`, `ARM64`, `splitway`. Workflow выбирают раннер по метке `splitway`.
- Версия: v2.338.2 из [actions/runner](https://github.com/actions/runner/releases), контрольная сумма архива сверена с описанием релиза. Раннер обновляется сам.
- Состояние: `~/actions-runner/splitway/svc.sh status`; журналы — `~/Library/Logs/actions.runner.facelessdiplomat-splitway.splitway-mac`.
- Переустановка: `./svc.sh stop && ./svc.sh uninstall`, затем `./config.sh remove --token <токен>` и регистрация заново с токеном из `gh api -X POST repos/facelessdiplomat/splitway/actions/runners/registration-token --jq .token`.
- В журналах заданий публичного репозитория видны имя раннера и имя компьютера.

## Настройки репозитория

После открытия репозитория (M8-06): workflow из PR внешних участников запускаются только после одобрения владельца (Settings → Actions → General → «Require approval for all external contributors»), GitHub Pages публикует из GitHub Actions, включены закрытые сообщения об уязвимостях.
