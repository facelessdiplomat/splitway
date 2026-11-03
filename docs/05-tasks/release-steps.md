# Выпуск на GitHub: шаги владельца

Splitway выходит образом DMG с подписью Developer ID и нотаризацией Apple в GitHub Releases (решение D-48), сайт живёт на GitHub Pages (D-49), исходный код открыт под GPL-3.0 (D-46). Аккаунт организации не нужен: Developer ID доступен и личному аккаунту (D-03 закрыто). В каждом шаге сказано, что делаете вы и что делаю я.

## 1. Данные для нотаризации — один раз

Нотаризация идёт от вашей учётной записи Apple Developer, поэтому данные для неё сохраняете вы, в связке ключей этого Mac. Ключи и пароли мне не присылайте.

1. **Ключ App Store Connect API:** App Store Connect → Users and Access → Integrations → App Store Connect API → «+», доступ Developer. Файл `.p8` скачивается только один раз: положите его в `~/.appstoreconnect/private_keys/`.
2. **Профиль в связке ключей:** в Терминале выполните, подставив свои Key ID и Issuer ID:

   ```bash
   xcrun notarytool store-credentials splitway-notary --key ~/.appstoreconnect/private_keys/AuthKey_<Key ID>.p8 --key-id <Key ID> --issuer <Issuer ID>
   ```

   Вместо ключа можно взять Apple ID и пароль приложения с appleid.apple.com: `xcrun notarytool store-credentials splitway-notary --apple-id <Apple ID> --team-id 8625S77CSU`, пароль команда спросит сама.
3. **Итог:** напишите мне, что профиль `splitway-notary` сохранён. Скрипт выпуска и раннер CI (он работает под вашей учётной записью macOS) берут данные оттуда.

## 2. Имя в подписи

Сертификат Developer ID называется по владельцу аккаунта Apple Developer: «Developer ID Application: <имя> (8625S77CSU)». Это имя видно каждому, кто посмотрит подпись приложения или образа, и macOS показывает его в некоторых окнах. Проверьте его командой `security find-identity -v -p codesigning | grep "Developer ID Application"`. Показать вместо него название компании можно только с аккаунтом организации.

## 3. Выпуск версии

Описание выпуска на английском и русском лежит в `docs/releases/<версия>.md` и попадает в `master` до тега: без него скрипт выпуска не публикует релиз. Описание 1.0 готово. После настройки CI (M8-05) выпуск идёт по тегу:

```bash
git tag v1.0 && git push origin v1.0
```

Раннер на этом Mac собирает архив, экспортирует его с подписью Developer ID, нотаризует приложение и образ и создаёт релиз `v1.0` с `Splitway.dmg` и контрольной суммой. Без CI то же делает `Scripts/release.sh 1.0 --publish` из чистой копии `master`. Установку DMG на чистой системе в тестовой ВМ проверяю я.

## 4. Открытие репозитория

Когда подготовка закончена (M8-06), я напишу, что всё готово. Публичным репозиторий делаете вы: GitHub → `facelessdiplomat/splitway` → Settings → General → Danger Zone → Change visibility → Public. После этого я включаю GitHub Pages и закрытые сообщения об уязвимостях. До открытия сайт не публикуется, а скачать DMG без входа в GitHub нельзя.

## 5. App Store

App Store не используется. Запись «Splitway Tunnel» в App Store Connect больше не нужна, удалять её не обязательно. Материалы для App Store — тексты, анкеты, заметки и ответ на отказ ревью 2026-11-03 — убраны в M8-06 и остались в истории git.
