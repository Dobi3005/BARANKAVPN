#!/usr/bin/env bash
# Баранка VPN — установка VLESS + Reality (Xray) на чистую Ubuntu 22.04/24.04
# Запуск:  sudo bash install_vless.sh
# Параметры (необязательно): PORT=443 SNI=www.microsoft.com NAME=Germany-1 sudo -E bash install_vless.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Запустите от root: sudo bash $0"; exit 1; }

PORT="${PORT:-443}"
SNI="${SNI:-www.microsoft.com}"   # сайт-«маска» с TLS 1.3 и h2
NAME="${NAME:-Baranka}"
CONF=/usr/local/etc/xray/config.json
META=/usr/local/etc/xray/baranka.env

export DEBIAN_FRONTEND=noninteractive
echo "==> Пакеты"
apt-get update -y
apt-get install -y curl jq openssl ufw qrencode ca-certificates

echo "==> BBR и сетевые буферы"
cat >/etc/sysctl.d/99-baranka.conf <<SYS
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3
fs.file-max=1048576
SYS
sysctl --system >/dev/null

echo "==> Xray"
bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
XRAY=/usr/local/bin/xray

KEYS="$($XRAY x25519)"
PRIV="$(echo "$KEYS" | awk -F': *' 'tolower($1) ~ /private/ {print $2}')"
PUB="$(echo "$KEYS"  | awk -F': *' 'tolower($1) ~ /public|password/ {print $2}')"
UUID="$($XRAY uuid)"
SHORT="$(openssl rand -hex 8)"
IP="$(curl -4 -fsS https://api.ipify.org)"
[[ -n "$PRIV" && -n "$PUB" ]] || { echo "Не удалось сгенерировать ключи x25519"; exit 1; }

echo "==> Конфиг"
jq -n --arg port "$PORT" --arg uuid "$UUID" --arg sni "$SNI" --arg priv "$PRIV" --arg sid "$SHORT" '
{
  log: {loglevel: "warning"},
  inbounds: [{
    listen: "0.0.0.0", port: ($port|tonumber), protocol: "vless",
    settings: {clients: [{id: $uuid, flow: "xtls-rprx-vision", email: "admin"}], decryption: "none"},
    streamSettings: {
      network: "tcp", security: "reality",
      realitySettings: {show: false, dest: ($sni + ":443"), xver: 0,
        serverNames: [$sni], privateKey: $priv, shortIds: [$sid]}
    },
    sniffing: {enabled: true, destOverride: ["http","tls","quic"]}
  }],
  outbounds: [{protocol: "freedom", tag: "direct"}, {protocol: "blackhole", tag: "block"}],
  routing: {domainStrategy: "IPIfNonMatch", rules: [
    {type: "field", protocol: ["bittorrent"], outboundTag: "block"},
    {type: "field", ip: ["geoip:private"], outboundTag: "block"}
  ]}
}' > "$CONF"

cat > "$META" <<M
IP=$IP
PORT=$PORT
SNI=$SNI
PUB=$PUB
SHORT=$SHORT
NAME=$NAME
M

echo "==> Файрвол"
SSH_PORT="$(grep -E '^\s*Port\s+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)"
SSH_PORT="${SSH_PORT:-22}"
ufw allow "${SSH_PORT}/tcp" >/dev/null
ufw allow "${PORT}/tcp" >/dev/null
ufw --force enable >/dev/null

# лимит открытых файлов для сотен клиентов
mkdir -p /etc/systemd/system/xray.service.d
printf '[Service]\nLimitNOFILE=1048576\n' > /etc/systemd/system/xray.service.d/limits.conf
systemctl daemon-reload
systemctl enable xray >/dev/null
systemctl restart xray
sleep 1
systemctl is-active --quiet xray || { journalctl -u xray -n 30 --no-pager; exit 1; }

LINK="vless://${UUID}@${IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${PUB}&sid=${SHORT}&type=tcp#${NAME}"

install -m 755 "$(dirname "$(readlink -f "$0")")/add_user.sh" /usr/local/bin/baranka-add 2>/dev/null || true
install -m 755 "$(dirname "$(readlink -f "$0")")/del_user.sh" /usr/local/bin/baranka-del 2>/dev/null || true

echo
echo "=============================================================="
echo " Готово! Ключ администратора (вставьте в приложение):"
echo
echo "$LINK"
echo
qrencode -t ANSIUTF8 "$LINK" || true
echo "=============================================================="
echo " Новый пользователь:  baranka-add имя_или_email"
echo " Удалить пользователя: baranka-del имя_или_email"
