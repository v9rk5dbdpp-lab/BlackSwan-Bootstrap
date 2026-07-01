# Roadmap

## v1.2 — 3x-ui

Status: implemented in branch `v1.2-install-3xui`.

Scope:

- модуль `modules/20_install_3xui.sh`;
- установка зависимостей;
- установка 3x-ui;
- проверка службы `x-ui`;
- идемпотентное поведение;
- подсказки по адресу панели;
- возврат в главное меню.

## v1.3 — SSL, Nginx, DNS

Planned:

- модуль SSL;
- модуль Nginx;
- выпуск сертификатов;
- проверка DNS;
- подготовка домена для сайтов и панелей;
- безопасная работа с уже существующими сертификатами.

## v1.4 — Python Platform

Planned:

- установка Python-инструментов;
- создание venv;
- установка pip-зависимостей;
- systemd-шаблон для Python-сервисов;
- шаблон Telegram-бота.

## v1.5 — Docker Platform

Planned:

- Docker;
- Docker Compose;
- Portainer;
- базовые команды диагностики контейнеров.

## v1.6 — Security and Diagnostics

Planned:

- Firewall;
- Fail2Ban;
- мониторинг;
- диагностика портов;
- диагностика systemd-служб;
- диагностика сетевой доступности.

## v2.0 — BlackSwan VPS Platform

Goal:

Универсальная платформа подготовки VPS для любых проектов BlackSwan Lab.
