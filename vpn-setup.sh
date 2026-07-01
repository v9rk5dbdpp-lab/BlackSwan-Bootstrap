#!/bin/bash

set -euo pipefail

MODULE_URL="https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/v1.3-vpn-test-kit/modules/25_vpn_test_kit.sh"
TMP_MODULE="/tmp/blackswan-vpn-test-kit.sh"

echo "=========================================="
echo "   BlackSwan Bootstrap"
echo "   One-command VPN setup"
echo "=========================================="
echo

if [ "$EUID" -ne 0 ]; then
    echo "Перезапускаю через sudo..."
    exec sudo bash -c "curl -fsSL '$MODULE_URL' -o '$TMP_MODULE' && bash '$TMP_MODULE'"
fi

curl -fsSL "$MODULE_URL" -o "$TMP_MODULE"
bash "$TMP_MODULE"
