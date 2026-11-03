# Security policy

Splitway handles WireGuard private keys and decides which traffic leaves the tunnel, so security reports get priority.

## Reporting a vulnerability

Report privately through GitHub: open the repository's **Security** tab and choose **[Report a vulnerability](https://github.com/facelessdiplomat/splitway/security/advisories/new)**. Please do not open a public issue.

Include what is affected (the app, the network extension or the Go engine), the Splitway and macOS versions, steps to reproduce and what an attacker could achieve. Do not send real keys or configurations; generate test keys instead.

We aim to reply within a week. Fixes ship in a new release, and the advisory is published once users can update.

## Supported versions

Only the latest release gets security fixes.

## Scope

In scope: leaks of keys or configurations, traffic of a selected app leaving outside the tunnel or the block-when-unavailable mode, bypasses of the XPC client check of the network extension, parsing of imported files and archives.

The threat model and the accepted risks are described (in Russian) in [docs/security.md](docs/security.md).
