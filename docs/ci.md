# CI

Своего CI у Splitway нет (решение D-54). Каждое изменение проверяет `Scripts/check.sh` на Mac разработчика, а хук `pre-merge-commit` не даёт слить ветку в `master` без зелёной проверки. Поэтому git-хуки включены в каждой рабочей копии: их ставит `Scripts/bootstrap.sh`, отдельно — `git config core.hooksPath Scripts/git-hooks`. Выпуск тоже собирается локально, командой `Scripts/release.sh <версия> --publish` ([шаги выпуска](05-tasks/release-steps.md), раздел 3).

С 2026-11-03 по 2026-11-24 проверку после пуша в `master` и выпуск по тегу выполнял собственный раннер на Mac владельца (решение D-47, задача M8-05). Раннер не выходил на связь с 2026-11-03, GitHub снял его регистрацию, и владелец не стал его восстанавливать: он повторял ту же проверку `check.sh`, а без него рядом с ключами подписи не выполняется ничей код. Workflow раннера `check.yml` и `release.yml` удалены (M8-11).

## Workflow

| Файл | Когда | Где | Что делает |
|---|---|---|---|
| `pull-request.yml` | pull request | облачный `macos-latest` | `gofmt`, проверка комментариев Go, `go vet` и `go test` всех Go-модулей; секретов не видит |
| `site.yml` | пуш в `master` с изменениями в `Site/`, ручной запуск | облачный `ubuntu-latest` | публикует `Site/` на GitHub Pages ([site.md](site.md)) |

Комментариев в YAML нет, как и в остальном коде (правила разработки, раздел 1).

## Сборки на Mac разработчика

- Сборки лежат в `build.noindex`: `check.sh`, `release.sh`, `install-ios-app.sh` и `bootstrap.sh` делают `build` ссылкой на эту папку (`Scripts/lib/build-directory.sh`). Иначе Spotlight индексирует сборки, и macOS показывает их среди приложений: 2026-11-03 вместо `/Applications/Splitway.app` так открылась неподписанная отладочная сборка из `check.sh`, собранная раннером.
- Xcode регистрирует в LaunchServices каждое собранное приложение. Номер сборки у копии из `release.sh` такой же, как у установленного выпуска, а у сборки для ВМ больше, и по bundle ID («Команды», Siri, `open -b`) macOS открыла бы их вместо `/Applications/Splitway.app`. Поэтому `release.sh` при выходе и `macos-vm.sh install` после копирования снимают регистрацию своих сборок (`Scripts/lib/launch-services.sh`).

## Настройки репозитория

Репозиторий открыт 2026-11-03 (M8-06). С тех пор workflow из PR внешних участников запускаются только после одобрения владельца (Settings → Actions → General → «Require approval for all external contributors»), GitHub Pages публикует из GitHub Actions, включены закрытые сообщения об уязвимостях. В журналах прошлых запусков раннера видно имя Mac `splitway-mac`; GitHub удаляет такие журналы через 90 дней.
