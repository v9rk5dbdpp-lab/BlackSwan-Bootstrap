#!/bin/bash

set -e

REPO_URL="https://github.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap.git"
RAW_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/main"

clear

echo "=========================================="
echo "       BlackSwan Bootstrap v1.1"
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
    echo "Установка 3x-ui пока будет добавлена следующим модулем."
    echo
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
    echo "Быстро проверить новый VPS перед установкой VPN."
    echo
    echo "Главные проверки:"
    echo "- доступность HTTP"
    echo "- примерная задержка"
    echo "- примерная скорость скачивания"
    echo
    echo "Стартовая страница специально оставлена простой."
    ;;

5)
    exit
    ;;

*)
    echo
    echo "Неверный выбор."
    ;;

esac