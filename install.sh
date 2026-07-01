#!/bin/bash

set -e

REPO_URL="https://github.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap.git"
RAW_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/main"
VERSION="v1.2"

run_module() {
    local module_path="$1"
    local module_url="$2"

    if [ -f "$module_path" ]; then
        bash "$module_path"
    else
        local tmp_module
        tmp_module="/tmp/$(basename "$module_path")"
        curl -fsSL "$module_url" -o "$tmp_module"
        bash "$tmp_module"
    fi
}

while true; do
    clear

    echo "=========================================="
    echo "       BlackSwan Bootstrap $VERSION"
    echo "=========================================="
    echo
    echo "1) Quick Start: проверить новый VPS"
    echo "2) Установить 3x-ui"
    echo "3) Обновить Bootstrap"
    echo "4) О проекте"
    echo "5) Выход"
    echo

    read -p "Выберите пункт: " CHOICE

    case $CHOICE in

    1)
        echo
        echo "Запуск проверки VPS..."
        echo

        if [ -f "./whitelist-test.sh" ]; then
            bash ./whitelist-test.sh
        else
            curl -fsSL "$RAW_URL/whitelist-test.sh" -o /tmp/whitelist-test.sh
            bash /tmp/whitelist-test.sh
        fi
        ;;

    2)
        echo
        echo "Запуск модуля установки 3x-ui..."
        echo
        run_module "./modules/20_install_3xui.sh" "$RAW_URL/modules/20_install_3xui.sh"
        ;;

    3)
        echo
        echo "Обновление Bootstrap..."
        if [ -d ".git" ]; then
            git pull
        else
            echo "Этот режим работает только внутри клонированного репозитория."
        fi
        ;;

    4)
        echo
        echo "BlackSwan Bootstrap"
        echo
        echo "Назначение:"
        echo "Быстро подготовить чистый Ubuntu VPS под проекты BlackSwan Lab."
        echo
        echo "Текущие возможности:"
        echo "- проверка нового VPS"
        echo "- whitelist-test HTTP-страница"
        echo "- примерная задержка"
        echo "- примерная скорость скачивания"
        echo "- идемпотентная установка 3x-ui"
        echo
        echo "Главный принцип: один модуль = одна задача."
        ;;

    5)
        exit
        ;;

    *)
        echo
        echo "Неверный выбор."
        ;;
    esac

    echo
    read -p "Нажмите Enter, чтобы вернуться в меню..." _
done
