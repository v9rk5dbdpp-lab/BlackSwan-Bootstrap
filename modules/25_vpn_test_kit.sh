#!/bin/bash

set -euo pipefail

VERSION="v1.3"
RAW_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/v1.3-vpn-test-kit"
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
    local packages=(curl wget ca-certificates unzip tar socat cron jq lsb-release ufw nginx)
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

install_network_test() {
    echo
    echo "========== Network Test =========="

    local tmp_script
    tmp_script="/tmp/blackswan-network-test.sh"

    if [ -f "./whitelist-test.sh" ]; then
        bash ./whitelist-test.sh
    else
        curl -fsSL "$RAW_URL/whitelist-test.sh" -o "$tmp_script"
        bash "$tmp_script"
    fi
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

show_ports_hint() {
    echo
    echo "========== Порты для проверки =========="
    echo
    echo "Минимально нужны входящие порты:"
    echo "- TCP 80  : Network Test"
    echo "- TCP порт панели 3x-ui: покажет установщик или команда x-ui settings"
    echo "- TCP 443 / 8443 / 2053 / 10443: будущие VPN inbound-тесты"
    echo
    echo "Если используется cloud security group, открой эти порты у провайдера."

    if command -v ufw >/dev/null 2>&1; then
        echo
        echo "Локальный UFW статус:"
        ufw status || true
    fi
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

Installed/prepared:
- Network Test page
- nginx
- 3x-ui / x-ui check
- base tools: curl wget unzip tar socat cron jq ufw

Open Network Test:
http://$public_ip/

Useful commands:
x-ui
x-ui settings
systemctl status x-ui --no-pager
systemctl status nginx --no-pager
ss -tulpn
ufw status

Next manual step:
Create VLESS REALITY inbound in 3x-ui and test Wi-Fi / MTS / Tele2.
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
    echo "Следующий шаг: открыть панель 3x-ui, создать VLESS REALITY inbound и тестировать Wi-Fi / MTS / Tele2."
}

print_header
require_root
require_ubuntu
install_dependencies
install_network_test
install_3xui
show_ports_hint
write_report
print_final
