#!/usr/bin/env bash
# Использование: baranka-add user@example.com  → печатает персональный vless:// ключ
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Нужен root"; exit 1; }
CONF=/usr/local/etc/xray/config.json
source /usr/local/etc/xray/baranka.env
ID="${1:?Укажите имя пользователя: baranka-add имя}"
if jq -e --arg e "$ID" '.inbounds[0].settings.clients[] | select(.email==$e)' "$CONF" >/dev/null; then
  echo "Пользователь $ID уже есть"; exit 1
fi
UUID="$(/usr/local/bin/xray uuid)"
tmp="$(mktemp)"
jq --arg id "$UUID" --arg e "$ID" \
  '.inbounds[0].settings.clients += [{"id":$id,"flow":"xtls-rprx-vision","email":$e}]' "$CONF" > "$tmp"
install -m 644 "$tmp" "$CONF"; rm -f "$tmp"
systemctl restart xray
echo "vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SHORT}&type=tcp#${NAME}"
