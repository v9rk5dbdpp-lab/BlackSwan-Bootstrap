#!/bin/bash

set -e

XUI_INSTALL_URL="https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh"

print_header() {
    echo
    echo "========== Установка 3x-ui =========="
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
    local packages=(curl ca-certificates lsb-release ufw)
    local missing=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "✅ Зависимости уже установлены"
        return
    fi

    echo "⚠️ Устанавливаем зависимости: ${missing[*]}"
    apt update
    apt install -y "${missing[@]}"
}

xui_exists() {
    command -v x-ui >/dev/null 2>&1 || [ -d /usr/local/x-ui ] || systemctl list-unit-files | grep -q '^x-ui.service'
}

show_xui_status() {
    echo
    echo "Статус службы x-ui:"
    if systemctl list-unit-files | grep -q '^x-ui.service'; then
        systemctl is-active --quiet x-ui && echo "✅ x-ui запущен" || echo "⚠️ x-ui установлен, но служба не активна"
        systemctl --no-pager --full status x-ui | sed -n '1,8p' || true
    else
        echo "⚠️ systemd-служба x-ui не найдена"
    fi
}

show_panel_hint() {
    local server_ip
    server_ip="$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"

    echo
    echo "========== Готово =========="
    echo
    echo "IP сервера: $server_ip"
    echo
    echo "Адрес панели, логин и пароль 3x-ui обычно показывает официальный установщик."
    echo "Если данные потерялись, используйте команду:"
    echo
    echo "    x-ui settings"
    echo
    echo "Или откройте меню управления:"
    echo
    echo "    x-ui"
    echo
    echo "SSL-сертификат не устанавливался. Это отдельный модуль v1.3."
}

install_3xui() {
    echo "⚠️ Запускаем официальный установщик 3x-ui"
    echo
    bash <(curl -Ls "$XUI_INSTALL_URL")
}

print_header
require_root
require_ubuntu
install_dependencies

if xui_exists; then
    echo
    echo "✅ 3x-ui уже установлен. Повторная установка пропущена."
    show_xui_status
    show_panel_hint
    exit 0
fi

install_3xui

if systemctl list-unit-files | grep -q '^x-ui.service'; then
    systemctl enable x-ui >/dev/null 2>&1 || true
    systemctl restart x-ui || true
fi

show_xui_status
show_panel_hint
