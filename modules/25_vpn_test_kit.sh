#!/bin/bash

set -euo pipefail

VERSION="v1.3"
NETWORK_TEST_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/v1.2.1-quickstart-test/whitelist-test.sh"
XUI_INSTALL_URL="https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh"
REPORT_DIR="/opt/blackswan-bootstrap"
REPORT_FILE="$REPORT_DIR/vpn-test-kit-report.txt"

print_header() {
    echo
    echo "=========================================="
    echo "   BlackSwan Bootstrap $VERSION"
    echo "   VPN Test Kit"
    echo "=========================================="
    echo
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Запустите модуль от root."
        exit 1
    fi
}

require_ubuntu() {
    if ! grep -qi ubuntu /etc/os-release; then
        echo "❌ Поддерживается только Ubuntu."
        exit 1
    fi
    . /etc/os-release
    echo "✅ Ubuntu $VERSION_ID"
}

install_dependencies() {
    local packages=(curl wget ca-certificates unzip tar socat cron jq lsb-release ufw nginx openssl net-tools iproute2 dnsutils htop nano)
    local missing=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "✅ Базовые зависимости уже установлены"
        return
    fi

    echo "⚠️ Устанавливаем зависимости: ${missing[*]}"
    apt update
    apt install -y "${missing[@]}"
}

enable_network_tuning() {
    echo
    echo "========== Network tuning =========="

    cat > /etc/sysctl.d/99-blackswan-vpn.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.tcp_fastopen=3
EOF

    sysctl --system >/dev/null || true

    echo "✅ sysctl profile applied"
    echo "TCP congestion: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
}

install_network_test() {
    echo
    echo "========== Network Test =========="

    local tmp_script
    tmp_script="/tmp/blackswan-network-test.sh"

    curl -fsSL "$NETWORK_TEST_URL" -o "$tmp_script"
    bash "$tmp_script"
}

xui_exists() {
    command -v x-ui >/dev/null 2>&1 || [ -d /usr/local/x-ui ] || systemctl list-unit-files | grep -q '^x-ui.service'
}

install_3xui() {
    echo
    echo "========== 3x-ui =========="

    if xui_exists; then
        echo "✅ 3x-ui уже установлен. Повторная установка пропущена."
    else
        echo "⚠️ Запускаем официальный установщик 3x-ui"
        bash <(curl -Ls "$XUI_INSTALL_URL")
    fi

    if systemctl list-unit-files | grep -q '^x-ui.service'; then
        systemctl enable x-ui >/dev/null 2>&1 || true
        systemctl restart x-ui || true
    fi

    if systemctl is-active --quiet x-ui; then
        echo "✅ x-ui запущен"
    else
        echo "⚠️ x-ui не активен. Проверьте: systemctl status x-ui"
    fi
}

prepare_firewall_hints() {
    echo
    echo "========== Firewall / ports =========="
    echo
    echo "Для работы VPN-тестов обычно нужны входящие TCP-порты:"
    echo "- 80    : Network Test"
    echo "- 443   : Reality / TLS tests"
    echo "- 8443  : alternate Reality / panel tests"
    echo "- 2053  : alternate Reality tests"
    echo "- 10443 : alternate Reality tests"
    echo "- порт панели 3x-ui: смотреть через x-ui settings"
    echo
    echo "Скрипт НЕ включает UFW насильно, чтобы не закрыть SSH."
    echo "Если UFW уже active, добавляем безопасные allow rules."

    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -qi "Status: active"; then
            ufw allow OpenSSH >/dev/null 2>&1 || true
            ufw allow 80/tcp >/dev/null 2>&1 || true
            ufw allow 443/tcp >/dev/null 2>&1 || true
            ufw allow 8443/tcp >/dev/null 2>&1 || true
            ufw allow 2053/tcp >/dev/null 2>&1 || true
            ufw allow 10443/tcp >/dev/null 2>&1 || true
            echo "✅ UFW active: базовые VPN-порты разрешены"
        else
            echo "✅ UFW не активен"
        fi
        ufw status || true
    fi
}

show_xui_access() {
    echo
    echo "========== 3x-ui access =========="
    echo
    echo "Команды для панели:"
    echo "x-ui"
    echo "x-ui settings"
    echo
    echo "Что нужно включить/создать в 3x-ui вручную:"
    echo "1) VLESS"
    echo "2) REALITY"
    echo "3) TCP"
    echo "4) flow: xtls-rprx-vision, если нужен Vision"
    echo "5) subscription link для клиента"
}

write_report() {
    local public_ip
    public_ip="$(curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}' || echo unknown)"

    mkdir -p "$REPORT_DIR"
    cat > "$REPORT_FILE" <<EOF
BlackSwan Bootstrap $VERSION — VPN Test Kit
Generated UTC: $(date -u)
Public IP: $public_ip
Hostname: $(hostname)

Prepared:
- Network Test page
- nginx
- 3x-ui / Xray panel
- base tools: curl wget unzip tar socat cron jq openssl ufw dnsutils htop nano
- network tuning: BBR, fq, ip_forward
- firewall hints / UFW safe allow if UFW was already active

Open Network Test:
http://$public_ip/

Useful commands:
x-ui
x-ui settings
systemctl status x-ui --no-pager
systemctl status nginx --no-pager
ss -tulpn
ufw status
cat /etc/sysctl.d/99-blackswan-vpn.conf

Next manual step:
Open 3x-ui, create VLESS REALITY inbound, copy subscription/config, test Wi-Fi / MTS / Tele2.
EOF

    echo
    echo "Отчет сохранен: $REPORT_FILE"
}

print_final() {
    local public_ip
    public_ip="$(curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}' || echo unknown)"

    echo
    echo "========== VPN Test Kit готов =========="
    echo
    echo "Network Test:"
    echo "http://$public_ip/"
    echo
    echo "3x-ui команды:"
    echo "x-ui"
    echo "x-ui settings"
    echo "systemctl status x-ui --no-pager"
    echo
    echo "Теперь сервер готов для создания VPN-конфигураций и подписок в 3x-ui."
}

print_header
require_root
require_ubuntu
install_dependencies
enable_network_tuning
install_network_test
install_3xui
prepare_firewall_hints
show_xui_access
write_report
print_final
