#!/bin/bash

set -e

WEB_ROOT="/var/www/html"
APP_DIR="$WEB_ROOT/blackswan"
INDEX_FILE="$WEB_ROOT/index.html"
REPORT_FILE="$APP_DIR/report.txt"

print_header() {
    echo "===================================="
    echo "   BlackSwan Bootstrap Quick Start"
    echo "===================================="
    echo
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Запустите скрипт от root."
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

check_internet() {
    if curl -fsS --max-time 5 https://api.ipify.org >/dev/null 2>&1; then
        echo "✅ Интернет доступен"
    else
        echo "❌ Нет доступа в интернет или недоступен внешний IP-сервис."
        exit 1
    fi
}

install_dependencies() {
    local packages=(nginx curl ca-certificates)
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

get_public_ip() {
    curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null || \
    curl -4 -fsS --max-time 5 https://ifconfig.me 2>/dev/null || \
    hostname -I | awk '{print $1}'
}

get_ipinfo_value() {
    local key="$1"
    local json="$2"
    echo "$json" | grep -oP '"'"$key"'":\s*"\K[^"]+' || echo "unknown"
}

create_test_file() {
    local file_path="$1"
    local size_mb="$2"

    if [ -f "$file_path" ]; then
        local current_size
        current_size=$(du -m "$file_path" | awk '{print $1}')
        if [ "$current_size" -ge "$size_mb" ]; then
            echo "✅ Тестовый файл уже есть: $(basename "$file_path")"
            return
        fi
    fi

    echo "⚠️ Создаем тестовый файл: $(basename "$file_path")"
    dd if=/dev/urandom of="$file_path" bs=1M count="$size_mb" status=none
}

backup_foreign_index() {
    if [ ! -f "$INDEX_FILE" ]; then
        return
    fi

    if grep -q "BlackSwan Bootstrap" "$INDEX_FILE"; then
        return
    fi

    local backup_file
    backup_file="$INDEX_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$INDEX_FILE" "$backup_file"
    echo "⚠️ Существующий index.html сохранен: $backup_file"
}

write_report() {
    local public_ip="$1"
    local org="$2"
    local city="$3"
    local region="$4"
    local country="$5"
    local generated_utc="$6"

    cat > "$REPORT_FILE" <<EOF
BlackSwan Bootstrap Quick Start Report

Public IP: $public_ip
Provider / ASN: $org
Location: $city, $region, $country
Hostname: $(hostname)
Generated UTC: $generated_utc

Test URLs:
http://$public_ip/
http://$public_ip/blackswan/test-1mb.bin
http://$public_ip/blackswan/test-10mb.bin
http://$public_ip/blackswan/test-50mb.bin
EOF
}

write_index() {
    local public_ip="$1"
    local org="$2"
    local city="$3"
    local region="$4"
    local country="$5"
    local generated_utc="$6"

    cat > "$INDEX_FILE" <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BlackSwan Bootstrap Quick Start</title>
<style>
body {
  background: #101820;
  color: white;
  font-family: Arial, sans-serif;
  margin: 0;
  padding: 24px;
}
.card {
  max-width: 860px;
  margin: auto;
  background: #1d2630;
  padding: 28px;
  border-radius: 20px;
  box-shadow: 0 0 25px rgba(0,255,120,.22);
}
h1 { font-size: 34px; margin-top: 0; }
.ok { color: #2ecc71; font-size: 26px; margin: 18px 0; }
.info { font-size: 17px; margin: 12px 0; line-height: 1.45; }
button {
  font-size: 18px;
  padding: 13px 18px;
  border: 0;
  border-radius: 12px;
  cursor: pointer;
  margin: 8px 6px 8px 0;
}
.result {
  margin-top: 18px;
  font-size: 18px;
  line-height: 1.55;
  color: #00ff88;
  word-break: break-word;
}
.small { color: #b9c2cc; font-size: 14px; }
code { background: #101820; padding: 3px 6px; border-radius: 6px; }
</style>
</head>
<body>
<div class="card">
<h1>🦢 BlackSwan Bootstrap</h1>
<div class="ok">HTTP REACHABLE</div>

<div class="info">🌍 Public IP:<br><b>$public_ip</b></div>
<div class="info">🏢 Provider / ASN:<br><b>$org</b></div>
<div class="info">📍 Location:<br><b>$city, $region, $country</b></div>
<div class="info">🖥 Hostname:<br><b>$(hostname)</b></div>
<div class="info">🕒 Generated UTC:<br><b>$generated_utc</b></div>

<hr>

<div class="info">Тест скорости с этого устройства до VPS:</div>
<button onclick="runSpeedTest('test-1mb.bin', 1)">1 MB</button>
<button onclick="runSpeedTest('test-10mb.bin', 10)">10 MB</button>
<button onclick="runSpeedTest('test-50mb.bin', 50)">50 MB</button>
<button onclick="copyResult()">Copy result</button>

<div class="result" id="result">Speed test not started</div>

<p class="small">
Проверяй отдельно Wi-Fi, MTS, Tele2, Beeline и другие сети. Один результат — одна маленькая монета в копилку эксперимента.
</p>

<p class="small">
Report: <code>/blackswan/report.txt</code>
</p>
</div>

<script>
let lastResult = "";

async function pingOnce() {
  const start = performance.now();
  await fetch("/?ping=" + Math.random(), { cache: "no-store" });
  return Math.round(performance.now() - start);
}

async function runSpeedTest(fileName, sizeMb) {
  const result = document.getElementById("result");
  result.innerHTML = "Testing " + sizeMb + " MB...";

  try {
    const latency = await pingOnce();
    const start = performance.now();
    const response = await fetch("/blackswan/" + fileName + "?cache=" + Math.random(), { cache: "no-store" });

    if (!response.ok) {
      throw new Error("HTTP " + response.status);
    }

    const blob = await response.blob();
    const end = performance.now();
    const seconds = (end - start) / 1000;
    const megabits = (blob.size * 8) / 1024 / 1024;
    const mbps = (megabits / seconds).toFixed(2);

    lastResult = [
      "BlackSwan VPS test",
      "IP: $public_ip",
      "Provider: $org",
      "Location: $city, $region, $country",
      "File: " + sizeMb + " MB",
      "Latency: " + latency + " ms",
      "Download: " + mbps + " Mbps",
      "User-Agent: " + navigator.userAgent
    ].join("\n");

    result.innerHTML =
      "Latency: " + latency + " ms<br>" +
      "Download: " + mbps + " Mbps<br>" +
      "File: " + sizeMb + " MB";
  } catch (error) {
    lastResult = "BlackSwan VPS test failed: " + error.message;
    result.innerHTML = "Test failed: " + error.message;
  }
}

async function copyResult() {
  if (!lastResult) {
    alert("Сначала запусти тест.");
    return;
  }
  await navigator.clipboard.writeText(lastResult);
  alert("Result copied.");
}
</script>
</body>
</html>
EOF
}

start_nginx() {
    systemctl enable nginx >/dev/null 2>&1
    systemctl restart nginx
    echo "✅ Nginx запущен"
}

print_summary() {
    local public_ip="$1"

    echo
    echo "========== Готово =========="
    echo
    echo "Открой на телефоне:"
    echo "http://$public_ip"
    echo
    echo "Прямые тестовые файлы:"
    echo "http://$public_ip/blackswan/test-1mb.bin"
    echo "http://$public_ip/blackswan/test-10mb.bin"
    echo "http://$public_ip/blackswan/test-50mb.bin"
    echo
    echo "Отчет на сервере:"
    echo "$REPORT_FILE"
}

print_header
require_root
require_ubuntu
check_internet
install_dependencies

mkdir -p "$APP_DIR"

PUBLIC_IP="$(get_public_ip)"
HOSTNAME="$(hostname)"
DATE_NOW="$(date -u)"
IPINFO="$(curl -fsS --max-time 5 https://ipinfo.io/json 2>/dev/null || echo '{}')"

ORG="$(get_ipinfo_value org "$IPINFO")"
CITY="$(get_ipinfo_value city "$IPINFO")"
COUNTRY="$(get_ipinfo_value country "$IPINFO")"
REGION="$(get_ipinfo_value region "$IPINFO")"

create_test_file "$APP_DIR/test-1mb.bin" 1
create_test_file "$APP_DIR/test-10mb.bin" 10
create_test_file "$APP_DIR/test-50mb.bin" 50

backup_foreign_index
write_report "$PUBLIC_IP" "$ORG" "$CITY" "$REGION" "$COUNTRY" "$DATE_NOW"
write_index "$PUBLIC_IP" "$ORG" "$CITY" "$REGION" "$COUNTRY" "$DATE_NOW"
start_nginx
print_summary "$PUBLIC_IP"
