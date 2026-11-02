# Заметки для App Review

App Review читает заметки по-английски. Блоки ниже вставляются в App Store Connect → версия → App Review Information → Notes, отдельно для iOS и macOS. Перед отправкой замените `[TEST CONFIGURATION]` ссылкой на тестовый конфиг или приложите файл `.conf` в поле Attachment: туда же можно приложить видео выбора сервисов `iphone-en.mp4` из материалов M7-07. Ваш личный ключ для этого не подходит, потому что ключ работает только на одном устройстве ([release-steps.md](../05-tasks/release-steps.md), шаг 8).

Поле Sign-in required — No: в приложении нет учётных записей.

## iOS и iPadOS

```text
Splitway is a WireGuard client. The developer does not operate VPN servers or sell VPN service: people import configurations from their own provider or server. No account or sign-in is needed, and the app collects no data.

Test configuration: [TEST CONFIGURATION]

1. Open Splitway and go through the short introduction.
2. Tap Import from file and choose the test configuration, or copy its text and tap Paste from clipboard. You can also scan it as a QR code.
3. Turn the tunnel on and allow the VPN configuration when iOS asks.
4. To see split tunneling: open the tunnel, tap Edit Tunnel, set Routing to Selected services, tap Choose Services…, pick a service and save. Only that service's domains and subnets go through the tunnel; other traffic uses the regular connection.

Encryption: WireGuard (ChaCha20-Poly1305, Curve25519, BLAKE2s).
```

## macOS

```text
Splitway is a WireGuard client for Mac. The developer does not operate VPN servers or sell VPN service: people import configurations from their own provider or server. No account or sign-in is needed, and the app collects no data.

Test configuration: [TEST CONFIGURATION]

1. Open Splitway from the Applications folder. On first launch it asks to allow its network extension: in System Settings › General › Login Items & Extensions › Network Extensions, turn on Splitway. The app guides you through this.
2. Import the test configuration: double-click the .conf file, or choose Import from file in Splitway.
3. Turn the tunnel on and allow the VPN configuration when macOS asks.
4. To see split tunneling: select the tunnel, click Edit Tunnel, set Routing to Selected apps, click Choose Apps…, select Safari and save. Safari's traffic goes through the tunnel; other apps use the regular connection.

The network extension is a system extension because it routes the traffic of selected apps with a transparent proxy for every user of the Mac. Encryption: WireGuard (ChaCha20-Poly1305, Curve25519, BLAKE2s).
```
