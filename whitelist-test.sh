#!/bin/bash

set -euo pipefail

VERSION="v1.2.1"
WEB_ROOT="/var/www/html"
TEST_DIR="$WEB_ROOT/blackswan"
INDEX_FILE="$WEB_ROOT/index.html"
REPORT_FILE="$TEST_DIR/report.txt"
BACKUP_FILE="$WEB_ROOT/index.html.blackswan-backup"

echo "===================================="
echo "   BlackSwan Bootstrap $VERSION"
echo "   Quick Start VPS Test"
echo "===================================="
echo

if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите от root: sudo bash whitelist-test.sh"
    exit 1
fi

if ! grep -qi ubuntu /etc/os-release; then
    echo "❌ Поддерживается только Ubuntu."
    exit 1
fi

. /etc/os-release
echo "✅ Ubuntu $VERSION_ID"

NEED_APT=0
for pkg in nginx curl ca-certificates; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        NEED_APT=1
    fi
done

if [ "$NEED_APT" -eq 1 ]; then
    echo "⚠️ Устанавливаем nginx/curl/ca-certificates"
    apt update
    apt install -y nginx curl ca-certificates
else
    echo "✅ Зависимости уже установлены"
fi

mkdir -p "$TEST_DIR"

if [ -f "$INDEX_FILE" ] && ! grep -q "BlackSwan Bootstrap" "$INDEX_FILE" && [ ! -f "$BACKUP_FILE" ]; then
    cp "$INDEX_FILE" "$BACKUP_FILE"
    echo "✅ Старый index.html сохранен: $BACKUP_FILE"
fi

PUBLIC_IP=$(curl -4 -fsS --max-time 8 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}' || echo "unknown")
HOSTNAME_VALUE=$(hostname)
DATE_NOW=$(date -u)
IPINFO=$(curl -fsS --max-time 8 https://ipinfo.io/json 2>/dev/null || echo "{}")
ORG=$(echo "$IPINFO" | grep -oP '"org":\s*"\K[^"]+' || echo "unknown")
CITY=$(echo "$IPINFO" | grep -oP '"city":\s*"\K[^"]+' || echo "unknown")
REGION=$(echo "$IPINFO" | grep -oP '"region":\s*"\K[^"]+' || echo "unknown")
COUNTRY=$(echo "$IPINFO" | grep -oP '"country":\s*"\K[^"]+' || echo "unknown")

create_file() {
    local mb="$1"
    local file="$TEST_DIR/test-${mb}mb.bin"

    if [ -f "$file" ]; then
        echo "✅ test-${mb}mb.bin уже есть"
    else
        echo "⚠️ Создаем test-${mb}mb.bin"
        dd if=/dev/zero of="$file" bs=1M count="$mb" status=none
    fi
}

create_file 1
create_file 10
create_file 50

cat > "$REPORT_FILE" <<EOF
BlackSwan Bootstrap $VERSION
Generated UTC: $DATE_NOW
Public IP: $PUBLIC_IP
Provider / ASN: $ORG
Location: $CITY, $REGION, $COUNTRY
Hostname: $HOSTNAME_VALUE

Open:
http://$PUBLIC_IP/

Files:
http://$PUBLIC_IP/blackswan/test-1mb.bin
http://$PUBLIC_IP/blackswan/test-10mb.bin
http://$PUBLIC_IP/blackswan/test-50mb.bin
EOF

cat > "$INDEX_FILE" <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BlackSwan Bootstrap VPS Test</title>
<style>
body{margin:0;background:#101820;color:white;font-family:Arial,sans-serif}.wrap{max-width:860px;margin:auto;padding:28px 18px}.card{background:#1d2630;padding:26px;border-radius:22px;box-shadow:0 0 28px rgba(0,255,120,.20)}h1{font-size:34px;margin:0 0 10px}.ok{color:#2ecc71;font-size:26px;margin:18px 0;font-weight:bold}.info{background:#263442;border-radius:14px;padding:14px;font-size:17px;margin:12px 0}.info b{color:#00ff88;word-break:break-word}button,a.btn{display:block;width:100%;box-sizing:border-box;font-size:18px;padding:14px 18px;margin:12px 0;border:0;border-radius:14px;background:#f4f7fb;color:#101820;text-align:center;text-decoration:none}.result{margin-top:18px;font-size:20px;color:#00ff88;line-height:1.5}.small{color:#b8c7d6;font-size:14px;margin-top:18px;line-height:1.5}
</style>
</head>
<body>
<div class="wrap"><div class="card">
<h1>🦢 BlackSwan Bootstrap</h1>
<div class="ok">HTTP REACHABLE</div>
<div class="info">🌍 Public IP:<br><b>$PUBLIC_IP</b></div>
<div class="info">🏢 Provider / ASN:<br><b>$ORG</b></div>
<div class="info">📍 Location:<br><b>$CITY, $REGION, $COUNTRY</b></div>
<div class="info">🖥 Hostname:<br><b>$HOSTNAME_VALUE</b></div>
<div class="info">🕒 Generated UTC:<br><b>$DATE_NOW</b></div>
<button onclick="runTest(1)">Quick test 1 MB</button>
<button onclick="runTest(10)">Normal test 10 MB</button>
<button onclick="runTest(50)">Heavy test 50 MB</button>
<a class="btn" href="/blackswan/report.txt">Open server report</a>
<div class="result" id="result">Speed test not started</div>
<div class="small">Запусти тест отдельно через Wi-Fi, MTS, Tele2 и другие сети. Запиши latency и download.</div>
</div></div>
<script>
async function runTest(size){
 const r=document.getElementById('result');
 r.innerHTML='Testing '+size+' MB...';
 try{
  const p0=performance.now();
  await fetch('/?ping='+Math.random(),{cache:'no-store'});
  const latency=Math.round(performance.now()-p0);
  const t0=performance.now();
  const response=await fetch('/blackswan/test-'+size+'mb.bin?cache='+Math.random(),{cache:'no-store'});
  const blob=await response.blob();
  const sec=(performance.now()-t0)/1000;
  const mbps=((blob.size*8/1024/1024)/sec).toFixed(2);
  r.innerHTML='Latency: '+latency+' ms<br>Download: '+mbps+' Mbps<br>File: '+size+' MB';
 }catch(e){r.innerHTML='Test failed: '+e;}
}
</script>
</body>
</html>
EOF

systemctl enable nginx >/dev/null 2>&1 || true
systemctl restart nginx

if systemctl is-active --quiet nginx; then
    echo "✅ nginx запущен"
else
    echo "❌ nginx не запустился"
    systemctl --no-pager status nginx | sed -n '1,12p' || true
    exit 1
fi

echo
echo "========== ГОТОВО =========="
echo "Открой на телефоне:"
echo "http://$PUBLIC_IP/"
echo
echo "Если страница не открывается, открой входящий TCP 80 в firewall/security group."
