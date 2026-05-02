#!/bin/bash

# Перевірка прав root
if [ "$EUID" -ne 0 ]; then
  echo "Запустіть скрипт з правами root: sudo ./install_dev_tools.sh"
  if [ -t 1 ]; then
  read -rp "Натисніть Enter для завершення..."
  fi
  exit 1
fi

echo "Встановлення інструментів DevOps"

apt-get update -qq

# curl
if ! command -v curl &>/dev/null; then
  echo "Встановлення curl..."
  apt-get install -y curl
fi

# Docker
if command -v docker &>/dev/null; then
  echo "[OK] Docker вже встановлено: $(docker --version)"
else
  echo "Встановлення Docker..."
  curl -fsSL "https://get.docker.com" | sh
  systemctl enable --now docker
  echo "[OK] Docker встановлено: $(docker --version)"
fi

# Docker Compose
if docker compose version &>/dev/null 2>&1 || command -v docker-compose &>/dev/null; then
  echo "[OK] Docker Compose вже встановлено"
else
  echo "Встановлення Docker Compose..."
  apt-get install -y docker-compose-plugin
  echo "[OK] Docker Compose встановлено: $(docker compose version)"
fi

# Python 3 (версія 3.9+)
NEED_INSTALL=true

if command -v python3 &>/dev/null; then
  PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
  PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
  
  if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 9 ]; then
    echo "[OK] Python вже встановлено: $(python3 --version)"
    NEED_INSTALL=false
  else
    echo "[WARN] Python $PY_VERSION < 3.9. Шукаємо новішу версію..."
  fi
fi

# Якщо Python немає, або він старіший за 3.9:
if [ "$NEED_INSTALL" = true ]; then
  echo "Встановлення Python 3.9+..."
  # Перебираємо версії від новіших до 3.9, встановлюємо першу доступну в репозиторії
  for VER in 3.12 3.11 3.10 3.9; do
    if apt-get install -y python${VER} python${VER}-venv python3-pip 2>/dev/null; then
      # Робимо встановлену версію дефолтною для команди python3
      update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${VER} 1
      echo "[OK] Python успішно встановлено/оновлено: $(python3 --version)"
      break
    fi
  done
fi

# pip3
if ! command -v pip3 &>/dev/null; then
  echo "Встановлення pip3..."
  apt-get install -y python3-pip
fi

# virtualenv
VENV_DIR="django_env"
if [ -d "$VENV_DIR" ]; then
  echo "[OK] Віртуальне середовище вже існує: $VENV_DIR"
else
  echo "Створення віртуального середовища '$VENV_DIR'..."
  python3 -m venv "$VENV_DIR"
  echo "[OK] Віртуальне середовище створено: $VENV_DIR"
fi

# Django (всередині venv)
if "$VENV_DIR/bin/python" -c "import django" &>/dev/null 2>&1; then
  echo "[OK] Django вже встановлено: $("$VENV_DIR/bin/python" -c 'import django; print(django.__version__)')"
else
  echo "Встановлення Django у віртуальне середовище..."
  if "$VENV_DIR/bin/pip" install django --quiet; then
    echo "[OK] Django встановлено: $("$VENV_DIR/bin/python" -c 'import django; print(django.__version__)')"
  else
    echo "[ERROR] Помилка встановлення Django"
    exit 1
  fi
fi

# Передаємо права на папку venv користувачу, який запустив скрипт через sudo
if [ -n "$SUDO_USER" ]; then
  chown -R "$SUDO_USER:$SUDO_USER" "$VENV_DIR"
fi

echo "[OK] Всі інструменти DevOps успішно встановлено!"
echo ""
echo "Віртуальне середовище створено, але не активовано автоматично."
echo ""
echo "Щоб почати роботу з Django, виконайте команду:"
echo "source $VENV_DIR/bin/activate"
if [ -t 1 ]; then
  read -rp "Натисніть Enter для завершення..."
fi