# Налаштування середовища DevOps (Bash Script)

Цей репозиторій містить Bash-скрипт `install_dev_tools.sh` для автоматизованого налаштування робочого середовища на системах Ubuntu/Debian.

## Що робить скрипт

Скрипт автоматично перевіряє наявність та встановлює (якщо потрібно) наступні інструменти:

- **Docker** (через офіційний інсталятор)
- **Docker Compose** (як плагін)
- **Python 3.9+** (з автоматичним пошуком найновішої версії та налаштуванням `update-alternatives`)
- **Django** (в ізольованому віртуальному середовищі `django_env`)

## Як використовувати

1. Клонуйте репозиторій:

   ```bash
   git clone -b lesson-3 https://github.com/MStartsev/DevOps-CI-CD.git
   cd DevOps-CI-CD
   ```

2. Зробіть скрипт виконуваним:

   ```bash
   chmod u+x install_dev_tools.sh
   ```

3. Запустіть скрипт з правами суперкористувача (sudo):

   ```bash
   sudo ./install_dev_tools.sh
   ```

4. Після завершення встановлення, активуйте віртуальне середовище Django:
   ```bash
   source django_env/bin/activate
   ```
