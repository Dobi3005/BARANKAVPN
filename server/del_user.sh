#!/usr/bin/env bash
# Использование: baranka-del user@example.com
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Нужен root"; exit 1; }
CONF=/usr/local/etc/xray/config.json
ID="${1:?Укажите имя пользователя}"
tmp="$(mktemp)"
jq --arg e "$ID" '.inbounds[0].settings.clients |= map(select(.email != $e))' "$CONF" > "$tmp"
install -m 644 "$tmp" "$CONF"; rm -f "$tmp"
systemctl restart xray
echo "Удалён: $ID"
