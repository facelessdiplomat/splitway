<p align="center"><img src="Site/images/icon-256.png" width="128" height="128" alt="Splitway icon"></p>

<h1 align="center">Splitway</h1>

<p align="center"><strong>VPN only for the apps that need it.</strong><br>
A free, open-source WireGuard® client for Mac with per-app split tunneling.</p>

<p align="center">
<a href="https://github.com/facelessdiplomat/splitway/releases/latest/download/Splitway.dmg">Download for Mac</a> ·
<a href="https://facelessdiplomat.github.io/splitway/">Website</a> ·
<a href="README.ru.md">Русский</a>
</p>

<p align="center"><img src="Site/images/main-en.png" width="720" alt="The Splitway window with a tunnel that routes only Safari and Terminal"></p>

## What it does

Splitway connects to the WireGuard server you bring — your own, on a router, or from a VPN provider. Unlike the official client, it lets you choose which apps go through the tunnel. Everything else stays on your regular connection.

- **Apps, not subnets.** Pick apps and command-line tools. Helpers and processes started by a selected app go with it: commands in a selected Terminal use the tunnel too.
- **DNS follows the app.** Name lookups of selected apps go through the tunnel, so they do not leak.
- **Blocked, not exposed.** If the tunnel drops, selected apps wait for it instead of going direct (configurable per tunnel).
- **All traffic when you need it**, with the option to exclude private networks, like the official client.
- **Your keys stay yours.** No accounts, no analytics, no developer servers. Keys live in the Keychain.
- Menu bar, launch at login, Shortcuts and Siri, English and Russian.

## Install

1. Download the latest [Splitway.dmg](https://github.com/facelessdiplomat/splitway/releases/latest/download/Splitway.dmg). Releases are signed with Developer ID and notarized by Apple.
2. Drag Splitway to Applications — the network extension starts only from there.
3. On first launch, allow the extension in System Settings › General › Login Items & Extensions › Network Extensions.
4. Import your WireGuard configuration, allow the VPN configuration when macOS asks, and connect.

Requires macOS 26 or later on Apple silicon or Intel.

## How it works

A network system extension hosts two providers. A transparent proxy (`NETransparentProxyProvider`) learns which app opened each TCP or UDP flow; flows of selected apps go through WireGuard running on a userspace network stack (wireguard-go with gVisor netstack), and the rest go back to macOS. A packet tunnel provider runs the classic All traffic mode. Only public APIs are used.

The app is Swift 6 with SwiftUI; the engine is Go behind a small C API. The design documents are in Russian: start with [docs/02-architecture.md](docs/02-architecture.md), and see the full list in [README.ru.md](README.ru.md#документация).

## Build from source

You need Xcode 27, Go 1.27, SwiftLint and XcodeGen (`brew install swiftlint xcodegen go`).

```bash
Scripts/bootstrap.sh
```

```bash
Scripts/check.sh
```

`bootstrap.sh` installs the git hooks, builds `TunnelCore.xcframework` and generates `Splitway.xcodeproj`; `check.sh` runs the linters, Go and Swift tests, the macOS build and, when Xcode has an iPhone simulator, the iOS build with its integration tests. To run your own signed build, set your team and bundle ID prefix (`DEVELOPMENT_TEAM`, `SPLITWAY_BUNDLE_ID_PREFIX`) in `project.yml`: a network system extension needs a signing identity with the Network Extension and System Extension capabilities, and it activates only from `/Applications`.

## Build for your iPhone

The same code builds for iPhone and iPad, but only for your own devices: there is no App Store, TestFlight or IPA release. iOS lets only device management choose apps for a VPN, so instead of apps the iPhone build chooses services: all traffic goes through the tunnel, or only the selected services do — 15 built-in ones such as Telegram, YouTube and ChatGPT, plus your own domains and networks. Everything else stays on your usual connection. The iPhone build also imports tunnels from QR codes and has a Control Center switch and Shortcuts. iPad runs the same app but is not tested.

You need:

- a paid Apple Developer Program membership: a free Apple ID cannot sign the Network Extension;
- Developer Mode on the iPhone (Settings › Privacy & Security › Developer Mode) and the iPhone paired with the Mac: connect it with a cable, unlock it and trust the Mac;
- your team and bundle ID prefix in `project.yml`, as for the Mac build above.

After `Scripts/bootstrap.sh`, connect the iPhone and run:

```bash
Scripts/install-ios-app.sh
```

It builds Splitway in the Release configuration, signed for development, and installs it on the connected iPhone or iPad; pass the device name or UDID when several are connected. You can also open `Splitway.xcodeproj` in Xcode, choose the `iOSApp` scheme and your device, and click Run.

A development profile lasts up to a year and only while the membership is paid. When it expires, Splitway stops opening: install it again the same way, and your tunnels and settings stay.

## Contributing

Bug reports and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Report security problems privately as described in [SECURITY.md](SECURITY.md).

## License

Splitway is released under the [GNU General Public License v3.0](LICENSE). Third-party components keep their own licenses, listed in the app under Settings › Licenses.

“WireGuard” is a registered trademark of Jason A. Donenfeld. Splitway is not affiliated with or endorsed by the WireGuard project.
