#!/bin/bash

set -euo pipefail

VERSION="v1.3"
NETWORK_TEST_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/v1.2.1-quickstart-test/whitelist-test.sh"
XUI_INSTALL_URL="https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh"
XUI_RESULT_FILE="/etc/x-ui/install-result.env"
REPORT_DIR="/opt/blackswan-bootstrap"
REPORT_FILE="$REPORT_DIR/vpn-setup-wizard.txt"

get_public_ip() {
    curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}' || echo unknown
}

print_header() {
    echo
    echo "=========================================="
    echo "   BlackSwan Bootstrap $VERSION"
    echo "   VPN Setup Wizard"
    echo "=========================================="
    echo
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Запусти от root или через sudo."
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

install_base_tools() {
    local packages=(curl wget ca-certificates unzip tar socat cron jq lsb-release ufw nginx openssl net-tools iproute2 dnsutils htop nano)
    local missing=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "⚠️ Устанавливаем компоненты: ${missing[*]}"
        apt update
        apt install -y "${missing[@]}"
    else
        echo "✅ Все базовые компоненты уже установлены"
    fi
}

setup_network_tuning() {
    cat > /etc/sysctl.d/99-blackswan-vpn.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.tcp_fastopen=3
EOF
    sysctl --system >/dev/null || true
    echo "✅ Network tuning применен: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
}

setup_network_test() {
    echo
    echo "========== Шаг 1: Network Test =========="
    local tmp_script="/tmp/blackswan-network-test.sh"
    curl -fsSL "$NETWORK_TEST_URL" -o "$tmp_script"
    bash "$tmp_script"

    local public_ip
    public_ip="$(get_public_ip)"
    echo
    echo "Проверь доступ и скорость:"
    echo "http://$public_ip/"
}

xui_exists() {
    command -v x-ui >/dev/null 2>&1 || [ -d /usr/local/x-ui ] || systemctl list-unit-files | grep -q '^x-ui.service'
}

install_xui_if_needed() {
    echo
    echo "========== Шаг 2: 3x-ui =========="

    if xui_exists; then
        echo "✅ 3x-ui уже установлен"
    else
        read -p "Установить 3x-ui и компоненты для VPN? [Y/n]: " ANSWER
        ANSWER="${ANSWER:-Y}"
        if [[ ! "$ANSWER" =~ ^[YyДд]$ ]]; then
            echo "Установка 3x-ui пропущена."
            return 0
        fi

        echo "⚠️ Запускаем официальный установщик 3x-ui"
        XUI_NONINTERACTIVE=1 bash <(curl -Ls "$XUI_INSTALL_URL")
    fi

    if systemctl list-unit-files | grep -q '^x-ui.service'; then
        systemctl enable x-ui >/dev/null 2>&1 || true
        systemctl restart x-ui || true
    fi

    if systemctl is-active --quiet x-ui; then
        echo "✅ x-ui запущен"
    else
        echo "⚠️ x-ui не активен. Проверь: systemctl status x-ui --no-pager"
    fi
}

get_panel_url() {
    if [ -f "$XUI_RESULT_FILE" ]; then
        grep '^XUI_ACCESS_URL=' "$XUI_RESULT_FILE" | cut -d= -f2- | sed "s/^'//;s/'$//" || true
    fi
}

show_result() {
    local public_ip panel_url
    public_ip="$(get_public_ip)"
    panel_url="$(get_panel_url)"
    [ -n "$panel_url" ] || panel_url="unknown"

    mkdir -p "$REPORT_DIR"
    cat > "$REPORT_FILE" <<EOF
BlackSwan Bootstrap $VERSION — VPN Setup Wizard
Generated UTC: $(date -u)
Public IP: $public_ip

Network Test:
http://$public_ip/

3x-ui panel:
$panel_url

Useful commands:
x-ui
x-ui settings
systemctl status x-ui --no-pager
systemctl status nginx --no-pager
ss -tulpn
ufw status
EOF

    echo
    echo "=========================================="
    echo "        Сервер готов к VPN-настройке"
    echo "=========================================="
    echo
    echo "Network Test:"
    echo "http://$public_ip/"
    echo
    echo "3x-ui panel:"
    echo "$panel_url"
    echo
    echo "Команды для панели:"
    echo "x-ui"
    echo "x-ui settings"
    echo
    echo "Отчет:"
    echo "$REPORT_FILE"
    echo
    echo "Следующий шаг: зайти в 3x-ui и создать VLESS REALITY inbound и подписку."
}

print_header
require_root
require_ubuntu
install_base_tools
setup_network_tuning
setup_network_test
install_xui_if_needed
show_result
