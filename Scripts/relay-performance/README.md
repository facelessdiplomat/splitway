# Замеры скорости ретрансляции (SP-3)

Скрипты спайка SP-3. Они остаются в ветке `spike/SP-3` как образец методики для M4-16, результаты — в [SP-3.md](../../docs/features/spikes/SP-3.md).

## Что нужно

- Тестовая ВМ (решение D-32) или Mac с одобренным расширением Splitway.
- RoutingProbe в `/Applications`: `Scripts/build-routing-probe.sh`, затем копия бандла в ВМ.
- Туннель `cz-prg` из конфига `SPLITWAY_TEST_TUNNEL_CONFIG`. Конфиг попадает в ВМ потоком, после замеров ВМ возвращается к чистому состоянию.

## Скрипты

| Скрипт | Где запускается | Что делает |
|---|---|---|
| `measure-mode.sh <метка>` | в ВМ | простой расширения 20 с; маршрут RoutingProbe против `curl`; задержка 10 подключений; 5 DNS-запросов к резолверу системы; загрузка одним потоком (3 × 100 МиБ) и двумя параллельно; CPU-секунды расширения на гигабайт и загрузка системы по `top` |
| `profile-mode.sh <метка>` | в ВМ | `sample` процесса расширения 6 с во время загрузки в `/tmp/sample-<метка>.txt` |
| `count-packets.sh <метка>` | в ВМ | пакеты `en0` за загрузку 100 МиБ: сколько исходящих пакетов на один входящий |
| `sample-categories.py <файлы>` | на хосте | собственное время функций из `sample` по частям: шифрование, wireguard-go, gVisor, рантайм Go, системные вызовы, код Swift |
| `sample-callers.py <файл> <функция>` | на хосте | откуда вызывается функция |
| `switch-routing.js`, `toggle-tunnel.js`, `tunnel-status.js`, `press-button.js` | `tart exec -i splitway-macos26 /usr/bin/osascript -l JavaScript - <аргументы> < <скрипт>` | режим и выбор приложений `cz-prg`, подключение, состояние туннелей, кнопка подтверждения |

## Порядок

1. Скрипты копируются в `/tmp` ВМ: `tart exec -i splitway-macos26 /bin/sh -c 'cat > /tmp/measure-mode.sh; chmod +x /tmp/measure-mode.sh' < measure-mode.sh`.
2. Туннель отключён: `Scripts/macos-vm.sh exec /tmp/measure-mode.sh direct`.
3. «Весь трафик»: `switch-routing.js "All traffic"`, подтверждение `press-button.js "Save and Restart"`, если туннель подключён; затем `measure-mode.sh`, `profile-mode.sh`, `count-packets.sh`.
4. «Только выбранные приложения»: `switch-routing.js "Selected apps" RoutingProbe` и те же замеры.
5. Профили забираются на хост через `tart exec splitway-macos26 cat /tmp/sample-<метка>.txt` и разбираются `python3 -I sample-categories.py`.

## Ограничения

- `speed.cloudflare.com` после нескольких десятков загрузок подряд отвечает 429, а файлы больше 50 МБ не отдаёт. `proof.ovh.net` разрешает две параллельные загрузки с одного адреса, третья получает 429.
- Через выходной сервер туннеля не открываются тестовые серверы Hetzner и Linode — и в режиме «Весь трафик» тоже.
- `/tmp` ВМ очищается при перезагрузке, скрипты копируются заново.
- Сеть ВМ идёт через NAT хоста, скорость меняется от прогона к прогону на 20–30 %. Сравнивать режимы стоит прогонами подряд, а расход CPU — в CPU-секундах на гигабайт.
