# Contributing to Splitway

Thanks for helping. Splitway is a small project with strict rules, so a short read here saves a round of review.

## Reporting a problem

Open an [issue](https://github.com/facelessdiplomat/splitway/issues) with your macOS version, the Splitway version from Settings, what you did and what happened. Issues are public: never attach WireGuard configurations, keys or crash reports. Security problems go through [SECURITY.md](SECURITY.md), not issues.

## Before you write code

For anything bigger than a fix, open an issue first and describe the change. Product decisions are recorded in [docs/00-decisions.md](docs/00-decisions.md) (in Russian); a change that contradicts one needs a new decision, not just a patch.

## Rules that the checks enforce

The full rules are in [docs/06-development-rules.md](docs/06-development-rules.md). The ones people trip over:

- **No comments in code** — none in Swift, Go, C or shell, including `MARK`, `TODO` and disabled code. Go compiler directives (`//export`, `//go:build`, the cgo preamble) are the only exception. Explain *why* in the feature document instead.
- **Tests first** for anything with logic: domain types, parsing, use cases, view models, adapters with their own logic, Go packages. Swift Testing, fakes instead of mocks, deterministic tests.
- **Layers**: `Core` of a feature imports neither SwiftUI nor system frameworks; the app wires everything in `Apps/*`.
- **Names say what and why**; no `Manager`, `Helper`, `Utils` suffixes; one main type per file.
- **Size limits**: functions up to 50 lines, types up to 300, files up to 400 (SwiftLint stops a merge above these).
- **Documentation is in Russian**, identifiers are in English. When a feature changes, update its `docs/features/<Feature>.md`.

## Workflow

1. Run `Scripts/bootstrap.sh` once: it installs the git hooks, builds the Go engine and generates the Xcode project.
2. Work on a branch named `feature/<task-id>-<slug>` or `fix/<slug>`.
3. Write commits in [Conventional Commits](https://www.conventionalcommits.org/) form in English, with the feature as the scope, for example `fix(TunnelImport): accept CRLF line endings`.
4. Run `Scripts/check.sh` before opening a pull request. Pull requests from forks are reviewed by hand before CI runs.

By contributing, you agree that your contribution is licensed under the [GPL-3.0](LICENSE).
