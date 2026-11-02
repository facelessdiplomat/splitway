# Ответы для анкет App Store Connect

Ответы подготовлены по тому, что Splitway делает на самом деле ([security.md](../security.md), политика конфиденциальности). Юридические пункты — экспорт шифрования и статус продавца в ЕС — решаете вы.

## Сведения о приложении (App Information)

| Поле | Ответ |
|---|---|
| Primary Category | Utilities |
| Secondary Category | Productivity |
| Content Rights: содержит или показывает чужой контент | No |
| Copyright | `2026 <имя владельца>`, пока аккаунт личный; после перевода (D-03) — `2026 <название организации>` |
| Privacy Policy URL | `https://facelessdiplomat.github.io/en/privacy.html`, для русской локализации — `https://facelessdiplomat.github.io/ru/privacy.html` |

## Версия (для каждой платформы)

| Поле | Ответ |
|---|---|
| Support URL | `https://facelessdiplomat.github.io/en/support.html`, для русской локализации — `https://facelessdiplomat.github.io/ru/support.html` |
| Marketing URL | можно оставить пустым или указать `https://facelessdiplomat.github.io/` |
| Тексты | [listing.en.md](listing.en.md), [listing.ru.md](listing.ru.md) |
| Скриншоты | [README.md](README.md), раздел «Скриншоты» |
| App Review Information | [review-notes.md](review-notes.md); Sign-in required — No; контакт — ваши имя, телефон и почта |
| Version Release | вручную или автоматически после одобрения — на ваш выбор |

## Возрастной рейтинг (Age Rating)

На все вопросы анкеты — None или No: в приложении нет насилия, откровенного и пугающего содержимого, азартных игр, рекламы, общения пользователей, пользовательского контента и неограниченного доступа к сайтам. Родительский контроль и проверка возраста — No. Итог — 4+.

## Конфиденциальность (App Privacy)

- **Data Collection:** No, we do not collect data from this app. На странице приложения будет «Данные не собираются».
- Отчёт о сбое уходит, только если человек сам отправит его через «Поделиться» и сам выберет получателя ([политика](../privacy-policy.ru.md), раздел «Когда данные покидают устройство»). Приложение при этом ничего не передаёт само.
- **Advertising Identifier (IDFA):** No.

## Цена и доступность (Pricing and Availability)

- **Price:** Free (решение D-42).
- **Страны:** выбираете вы ([release-steps.md](../05-tasks/release-steps.md), шаг 2).
- **Статус продавца в ЕС (DSA):** указываете вы.

## Экспорт шифрования (Encryption)

Сверено с [требованиями Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/) 2026-11-03.

- **Случай Splitway** — стандартные алгоритмы не из системы: WireGuard шифрует трафик ChaCha20-Poly1305, Curve25519 и BLAKE2s (стандарты IETF) в собственном движке, а не через шифрование Apple.
- **App Encryption Documentation** (App Information): для этого случая Apple требует только французскую декларацию о шифровании, и только если приложение продаётся во Франции. Без Франции загружать ничего не нужно. CCATS нужен лишь для собственных, нестандартных алгоритмов — это не наш случай.
- **Вопросы у каждой сборки:** тип алгоритмов — «Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system»; затем вопрос про Францию — по списку стран.
- **Франция:** декларацию подают во французское агентство ANSSI, ответ приходит не сразу. Её можно подать позже и добавить Францию в страны со следующей версией.
- Решение юридическое и за владельцем; США Apple для этого случая документов не требует.
