#!/bin/bash

set -e

echo "===================================="
echo "   BlackSwan Bootstrap"
echo "===================================="

apt update
apt install -y nginx curl

mkdir -p /var/www/html/blackswan
mkdir -p /var/www/html/blackswan/assets

PUBLIC_IP=$(curl -4 -s ifconfig.me || echo "unknown")
HOSTNAME=$(hostname)
DATE_NOW=$(date -u)
IPINFO=$(curl -s https://ipinfo.io/json || echo "{}")

ORG=$(echo "$IPINFO" | grep -oP '"org":\s*"\K[^"]+' || echo "unknown")
CITY=$(echo "$IPINFO" | grep -oP '"city":\s*"\K[^"]+' || echo "unknown")
COUNTRY=$(echo "$IPINFO" | grep -oP '"country":\s*"\K[^"]+' || echo "unknown")
REGION=$(echo "$IPINFO" | grep -oP '"region":\s*"\K[^"]+' || echo "unknown")

dd if=/dev/urandom of=/var/www/html/blackswan/test-10mb.bin bs=1M count=10 status=none

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>BlackSwan Bootstrap</title>
<style>
body {
  background: #101820;
  color: white;
  font-family: Arial, sans-serif;
  text-align: center;
  padding: 40px;
}
.card {
  max-width: 760px;
  margin: auto;
  background: #1d2630;
  padding: 32px;
  border-radius: 20px;
  box-shadow: 0 0 25px rgba(0,255,120,.25);
}
h1 { font-size: 42px; }
.ok { color: #2ecc71; font-size: 30px; margin: 20px; }
.info { font-size: 18px; margin: 12px; }
button {
  font-size: 20px;
  padding: 14px 24px;
  border: 0;
  border-radius: 12px;
  cursor: pointer;
}
.result {
  margin-top: 20px;
  font-size: 22px;
  color: #00ff88;
}
</style>
</head>
<body>
<div class="card">
<h1>🦢 BlackSwan Bootstrap</h1>
<div class="ok">HTTP REACHABLE</div>

<div class="info">🌍 Public IP:<br><b>$PUBLIC_IP</b></div>
<div class="info">🏢 Provider / ASN:<br><b>$ORG</b></div>
<div class="info">📍 Location:<br><b>$CITY, $REGION, $COUNTRY</b></div>
<div class="info">🖥 Hostname:<br><b>$HOSTNAME</b></div>
<div class="info">🕒 Generated UTC:<br><b>$DATE_NOW</b></div>

<button onclick="runSpeedTest()">Run Speed Test</button>
<div class="result" id="result">Speed test not started</div>
</div>

<script>
async function runSpeedTest() {
  const result = document.getElementById("result");
  result.innerHTML = "Testing...";

  const pingStart = performance.now();
  await fetch("/?ping=" + Math.random(), { cache: "no-store" });
  const latency = Math.round(performance.now() - pingStart);

  const start = performance.now();
  const response = await fetch("/blackswan/test-10mb.bin?cache=" + Math.random(), { cache: "no-store" });
  const blob = await response.blob();
  const end = performance.now();

  const seconds = (end - start) / 1000;
  const megabits = (blob.size * 8) / 1024 / 1024;
  const mbps = (megabits / seconds).toFixed(2);

  result.innerHTML =
    "Latency: " + latency + " ms<br>" +
    "Download: " + mbps + " Mbps";
}
</script>
</body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx

echo
echo "Done."
echo "Open in Safari:"
echo "http://$PUBLIC_IP"