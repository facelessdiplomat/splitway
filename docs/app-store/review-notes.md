# Заметки для App Review

App Review читает заметки по-английски. Блоки ниже вставляются в App Store Connect → версия → App Review Information → Notes, отдельно для iOS и macOS; поле вмещает 4000 знаков. Перед отправкой замените `[TEST CONFIGURATION]` ссылкой на тестовый конфиг или приложите файл `.conf` в поле Attachment: туда же можно приложить видео выбора сервисов `iphone-en.mp4` из материалов M7-07. Ваш личный ключ для этого не подходит, потому что ключ работает только на одном устройстве ([release-steps.md](../05-tasks/release-steps.md), шаг 8).

Поле Sign-in required — No: в приложении нет учётных записей.

Раздел «VPN and user data» отвечает на вопросы, которые App Review задаёт VPN-приложениям: какие данные о пользователе собираются, зачем и передаются ли третьим лицам. В заметках macOS есть ещё раздел о праве `com.apple.security.network.server`. Оба ответа Apple просит держать в App Review Information (отказ 2026-11-03, раздел ниже).

## iOS и iPadOS

```text
Splitway is a WireGuard client. The developer does not operate VPN servers or sell VPN service: people import configurations from their own provider or server. No account or sign-in is needed, and the app collects no data.

Test configuration: [TEST CONFIGURATION]

1. Open Splitway and go through the short introduction.
2. Tap Import from file and choose the test configuration, or copy its text and tap Paste from clipboard. You can also scan it as a QR code.
3. Turn the tunnel on and allow the VPN configuration when iOS asks.
4. To see split tunneling: open the tunnel, tap Edit Tunnel, set Routing to Selected services, tap Choose Services…, pick a service and save. Only that service's domains and subnets go through the tunnel; other traffic uses the regular connection.

Encryption: WireGuard (ChaCha20-Poly1305, Curve25519, BLAKE2s).

VPN and user data
- What user information does the app collect using VPN? None. The app has no accounts, analytics, ads or tracking and never contacts the developer's servers. Tunnel configurations and keys stay on the device, in the keychain.
- For what purposes? Not applicable. To send only the chosen services through the tunnel, the app recognizes their domains in DNS queries on the device; nothing is stored or sent anywhere.
- Is the data shared with third parties? No. The developer receives no data. The traffic the user chooses goes to the WireGuard server named in the user's own configuration, run by the user or their VPN provider. If the configuration names no DNS server, DNS queries for the chosen services go through the tunnel to the public resolver 1.1.1.1; the app does not store or log them.
The first-run introduction says this on its second page, "Your data stays with you", before the app can be used.
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

VPN and user data
- What user information does the app collect using VPN? None. The app has no accounts, analytics, ads or tracking and never contacts the developer's servers. Tunnel configurations and keys stay on the Mac, in the keychain.
- For what purposes? Not applicable. To send only the chosen apps through the tunnel, the network extension checks on the Mac which app opens each connection; nothing is stored or sent anywhere.
- Is the data shared with third parties? No. The developer receives no data. The traffic the user chooses goes to the WireGuard server named in the user's own configuration, run by the user or their VPN provider. If the configuration names no DNS server, DNS queries of the chosen apps go through the tunnel to the public resolver 1.1.1.1, so they do not leak outside it; the app does not store or log them.
The first-run introduction says this on its second page, "Your data stays with you", before the app can be used.

Entitlement com.apple.security.network.server
Only the network extension (com.facelessdiplomat.splitway.network-extension) has it; the app does not. The extension runs WireGuard, a UDP protocol: it opens a UDP socket and receives on it the encrypted packets that the WireGuard server sends back. If the configuration sets ListenPort, the extension also accepts handshakes from peers on that port. In the App Sandbox, binding a UDP socket and receiving datagrams from peers on it require network.server: with network.client alone the system returns "Operation not permitted", and the tunnel cannot connect.
```

## Ответ на отказ macOS 1.0 (2026-11-03)

App Review отклонил первую отправку Mac-версии по трём пунктам.

| Пункт | Что это | Что делать |
|---|---|---|
| 5.4 Legal: VPN Apps | VPN-приложения принимают только от аккаунтов организаций, а аккаунт личный (D-03) | Перевести этот же аккаунт в организацию ([release-steps.md](../05-tasks/release-steps.md), шаг 1). До перевода не отправлять ни Mac-, ни iOS-версию |
| 2.1 App Completeness | Автоматический запрос: какие данные VPN собирает о пользователе, зачем и кому их передаёт | Ответ ниже и раздел «VPN and user data» в заметках |
| 2.4.5 Hardware Compatibility | Автоматическая проверка нашла у сборки право `com.apple.security.network.server`, но не нашла сервера | Право нужно расширению: без него песочница не даёт wireguard-go принимать пакеты ([SystemExtension](../features/SystemExtension.md), «Спорные решения»). Ответ ниже и раздел о праве в заметках macOS |

Что сделать:

1. Замените заметки macOS в App Review Information блоком выше: Apple просит держать там ответы о VPN и о праве.
2. Ответьте на сообщение App Review в App Store Connect текстом ниже. Третий пункт оставьте, только если запрос на перевод аккаунта уже отправлен.
3. Отправляйте версию снова только из аккаунта организации. Apple предупредил: повторные отправки с теми же проблемами продлевают ревью, а аккаунты, которые раз за разом нарушают правила, исключают из программы.

```text
Hello,

Thank you for the review. Here are the answers to your questions.

1. VPN functionality
- What user information is the app collecting using VPN? None. Splitway is a WireGuard client for the user's own server or VPN provider. It has no accounts, analytics, ads or tracking and never contacts the developer's servers. Tunnel configurations and keys stay on the Mac, in the keychain.
- For what purposes are you collecting this information? Not applicable: no data is collected. To send only the chosen apps through the tunnel, the network extension checks on the Mac which app opens each connection; nothing is stored or sent anywhere.
- Will the data be shared with any third parties? No. The developer receives no data. The traffic the user chooses goes to the WireGuard server named in the user's own configuration. If the configuration names no DNS server, DNS queries of the chosen apps go through the tunnel to the public resolver 1.1.1.1, so they do not leak outside it; the app does not store or log them.

2. com.apple.security.network.server
Only the network extension (com.facelessdiplomat.splitway.network-extension) has this entitlement; the app does not. The extension runs WireGuard, a UDP protocol: it opens a UDP socket and receives on it the encrypted packets that the WireGuard server sends back. If the configuration sets ListenPort, the extension also accepts handshakes from peers on that port. In the App Sandbox, binding a UDP socket and receiving datagrams from peers on it require network.server: with network.client alone the system returns "Operation not permitted", and the tunnel cannot connect.

We have added both answers to the App Review Information section.

3. Guideline 5.4
We are converting our Apple Developer Program membership from Individual to Organization and will resubmit from the organization account.
```
