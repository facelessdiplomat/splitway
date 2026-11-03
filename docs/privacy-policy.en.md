# Splitway Privacy Policy

Version of November 3, 2026. Applies to Splitway for Mac.

## In short

Splitway does not collect data. The app has no accounts, analytics, ads or tracking, and it never contacts the developer's servers. We do not sell, use or disclose any user data to third parties for any purpose.

## What stays on your device

Everything Splitway needs stays on your device:

- **WireGuard tunnel configurations, including private keys.** They are kept in the keychain and are not synced through iCloud. Splitway's network extension receives a copy of the configuration and keeps it in the system keychain.
- **Tunnel names and routing settings:** which apps use the tunnel.
- **Diagnostic log:** connection and disconnection times, errors and tunnel names. Keys are never written to the log. The log takes at most 2 MB, and old entries are deleted automatically.
- **Crash reports** that the system hands to the app on the device (the latest 20 at most).
- **Internal settings,** such as whether you have finished the first-run introduction.

## Network traffic

Splitway is a WireGuard client. The traffic you choose goes to the VPN server named in the tunnel configuration. You or your VPN provider choose and set up that server. The developer of Splitway has nothing to do with it and cannot see your traffic. How data is handled on the server is up to its operator.

To send only what you chose through the tunnel, Splitway identifies which app opens a connection. This happens only on the device: addresses, site names and connection lists are neither stored nor sent anywhere.

## Permissions

- **VPN configuration** — to connect tunnels.
- **Network extension** — to route the traffic of the chosen apps. Splitway reads the list of installed apps and their signatures to show them to you when you choose and to recognize the chosen apps.

## When data leaves the device

Splitway sends nothing by itself. Data leaves the device only when you act, and you choose the recipient:

- **Tunnel export** — a file with private keys. The app warns you about this before exporting.
- **Log export** — a text file.
- **Crash report** — an archive with the log and system reports that you send through the Share menu.

If you send a report to the developer yourself, it is used only to find and fix the problem and is never passed to third parties.

If "Share With App Developers" is turned on in System Settings, Apple may share crash reports and usage statistics with developers. This is governed by Apple's privacy policy. You can turn this setting on or off in System Settings under Privacy & Security.

## Retention and deletion

Data stays on the device until you delete it:

- deleting a tunnel erases its configuration and keys;
- Clear Log erases the log;
- Uninstall Splitway… in Settings erases the tunnels with their keys, including the copy in the system keychain, the VPN configurations, the app's data and the network extension. Moving the app to the Trash leaves all of this in place.

The developer has none of your data, so no separate deletion request is needed. If you have sent us a crash report, write to us and we will delete it.

## Changes to this policy

A new version is published on this page with a new date.

## Contact

You can reach the developer through the support page on the app's website or through the project's GitHub Issues.
