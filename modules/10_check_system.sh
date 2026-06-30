#!/bin/bash

echo
echo "========== Проверка системы =========="

# Root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите скрипт от root."
    exit 1
else
    echo "✅ Root"
fi

# Ubuntu
if grep -qi ubuntu /etc/os-release; then
    . /etc/os-release
    echo "✅ Ubuntu $VERSION_ID"
else
    echo "❌ Поддерживается только Ubuntu."
    exit 1
fi

# Интернет
if ping -c1 1.1.1.1 >/dev/null 2>&1; then
    echo "✅ Интернет"
else
    echo "❌ Нет доступа в интернет."
    exit 1
fi

# curl
if command -v curl >/dev/null 2>&1; then
    echo "✅ curl"
else
    echo "⚠️ curl отсутствует. Устанавливаем..."
    apt update
    apt install -y curl
fi

# Git
if command -v git >/dev/null 2>&1; then
    echo "✅ Git"
else
    echo "⚠️ Git отсутствует. Устанавливаем..."
    apt update
    apt install -y git
fi

echo
echo "Проверка завершена."