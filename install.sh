#!/bin/bash

set -e

clear

echo "=========================================="
echo "       BlackSwan Bootstrap v1.0"
echo "=========================================="
echo
echo "1) Проверить сервер"
echo "2) Установить 3x-ui"
echo "3) Обновить Bootstrap"
echo "4) О проекте"
echo "5) Выход"
echo

read -p "Выберите пункт: " CHOICE

case $CHOICE in

1)
    bash whitelist-test.sh
    ;;

2)
    if [ -f install-3x-ui.sh ]; then
        bash install-3x-ui.sh
    else
        echo
        echo "install-3x-ui.sh пока отсутствует."
    fi
    ;;

3)
    git pull
    ;;

4)
    echo
    echo "BlackSwan Bootstrap"
    echo
    echo "Назначение:"
    echo "Быстрая проверка VPS перед установкой VPN."
    echo
    echo "Этапы:"
    echo "✔ Проверка HTTP"
    echo "✔ Проверка скорости"
    echo "✔ Установка 3x-ui"
    ;;

5)
    exit
    ;;

*)
    echo
    echo "Неверный выбор."
    ;;

esac