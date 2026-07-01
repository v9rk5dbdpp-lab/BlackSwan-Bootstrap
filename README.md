# BlackSwan Bootstrap

BlackSwan Bootstrap — модульная система подготовки чистого Ubuntu VPS под проекты BlackSwan Lab.

Цель проекта — не один большой `install.sh`, а набор понятных модулей, где каждый модуль отвечает за одну задачу.

## Текущая версия

**v1.2.1-dev**

Реализовано:

- главное меню;
- Quick Start для проверки нового VPS;
- улучшенная whitelist-test HTTP-страница;
- тестовые файлы 1 MB, 10 MB и 50 MB;
- модуль проверки системы;
- идемпотентный модуль установки 3x-ui;
- базовая проектная документация.

## Главный принцип

```text
Один модуль = одна задача.
```

Повторный запуск Bootstrap не должен ломать уже настроенный сервер. Если компонент уже установлен, модуль обязан аккуратно сообщить об этом и пропустить опасные действия.

## Быстрый запуск

Проверка нового VPS из стабильной ветки `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/main/whitelist-test.sh | sudo bash
```

Тест текущей ветки разработки v1.2.1:

```bash
curl -fsSL https://raw.githubusercontent.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap/v1.2.1-quickstart-test/whitelist-test.sh | sudo bash
```

Полное меню Bootstrap:

```bash
git clone https://github.com/v9rk5dbdpp-lab/BlackSwan-Bootstrap.git
cd BlackSwan-Bootstrap
chmod +x install.sh modules/*.sh
sudo ./install.sh
```

## Структура проекта

```text
install.sh
modules/
  10_check_system.sh
  20_install_3xui.sh
whitelist-test.sh
README.md
CHANGELOG.md
PROJECT_HISTORY.md
ROADMAP.md
```

## Quick Start: проверка нового VPS

Скрипт `whitelist-test.sh`:

- проверяет root-доступ;
- проверяет Ubuntu;
- проверяет доступ в интернет;
- устанавливает недостающие зависимости;
- запускает Nginx;
- создает диагностическую HTTP-страницу;
- создает тестовые файлы 1 MB, 10 MB и 50 MB;
- сохраняет краткий отчет в `/var/www/html/blackswan/report.txt`;
- при повторном запуске не пересоздает тестовые файлы без необходимости;
- если на сервере уже был чужой `index.html`, сохраняет резервную копию.

После запуска нужно открыть с телефона:

```text
http://SERVER_IP
```

И отдельно проверить Wi-Fi и мобильные сети.

## v1.2: установка 3x-ui

Модуль `modules/20_install_3xui.sh`:

- проверяет root-доступ;
- проверяет Ubuntu;
- устанавливает недостающие зависимости;
- проверяет, установлен ли уже 3x-ui;
- не переустанавливает 3x-ui повторно без необходимости;
- запускает официальный установщик 3x-ui;
- проверяет службу `x-ui`;
- показывает IP сервера и подсказки по панели;
- оставляет SSL на отдельный модуль v1.3.

## План развития

- v1.3: SSL, Nginx, сертификаты, DNS;
- v1.4: Python Platform, venv, pip, systemd, шаблон Telegram-бота;
- v1.5: Docker, Docker Compose, Portainer;
- v1.6: Firewall, Fail2Ban, мониторинг, диагностика;
- v2.0: универсальная платформа подготовки VPS для проектов BlackSwan Lab.
