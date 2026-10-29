# Splitway

> Рабочее название. Нативный клиент для протокола WireGuard® на macOS, iOS и iPadOS: пользователь добавляет свой конфиг и выбирает, чей трафик идёт через VPN. На macOS выбираются приложения, на iOS/iPadOS — сервисы.

Сейчас идёт веха M0: каркас проекта, линтеры, сборка Go-ядра и локальные проверки.

## Быстрый старт

Нужны Xcode 27, Go 1.27, SwiftLint и XcodeGen (`brew install swiftlint xcodegen go`).

1. `Scripts/bootstrap.sh` — устанавливает git-хуки, собирает `TunnelCore.xcframework` и генерирует `Splitway.xcodeproj`.
2. `Scripts/check.sh` — все проверки: линтеры, тесты Go и Swift, сборка iOS и macOS, интеграционные тесты с хост-приложением на симуляторе iPhone. Хук `pre-merge-commit` запускает его при каждом слиянии в `main`. `Scripts/check.sh --ui` дополнительно запускает UI-тесты и аудит доступности на симуляторах iPhone и iPad.
3. Открыть `Splitway.xcodeproj` в Xcode.

Тестовый туннель для спайков и тестов утечек настраивается по [Scripts/test-tunnel/README.md](Scripts/test-tunnel/README.md). Реальные конфиги и ключи в репозиторий не попадают.

Если `xcode-select -p` указывает на Command Line Tools, скрипты сами используют `/Applications/Xcode.app`. Постоянное исправление: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

## Документация

| Документ | О чём |
|---|---|
| [00. Журнал решений](docs/00-decisions.md) | Все решения владельца, принятые до начала разработки, и отложенные вопросы |
| [01. Продукт](docs/01-product.md) | Что за продукт, для кого, функции, ограничения платформ, распространение, открытые вопросы |
| [02. Архитектура](docs/02-architecture.md) | Общая архитектура, стек, фичи и слои, хранение, Go-движок, архитектурные решения |
| [03. macOS](docs/03-platform-macos.md) | Системное расширение, transparent proxy, выбор приложений, выпуск через Developer ID |
| [04. iOS и iPadOS](docs/04-platform-ios-ipados.md) | Пакетный туннель, выбор сервисов, Controls, распространение |
| [05. План задач](docs/05-tasks/README.md) | Вехи M0–M7, 117 задач с критериями готовности |
| [06. Правила разработки](docs/06-development-rules.md) | Обязательные правила кода, тестов, коммитов и документации |
| [Документы фич](docs/features/_TEMPLATE.md) | Шаблон документа, который создаётся по завершении каждой фичи |

«WireGuard» — зарегистрированный товарный знак Jason A. Donenfeld. Проект не связан с проектом WireGuard и не одобрен им.
