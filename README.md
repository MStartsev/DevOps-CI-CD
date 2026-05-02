# Django Project

Django-застосунок із PostgreSQL та Nginx, контейнеризований за допомогою Docker / Docker Compose.

## Стек

- **Django** — вебфреймворк
- **PostgreSQL** — база даних
- **Nginx** — вебсервер / реверс-проксі
- **Gunicorn** — WSGI-сервер
- **Docker / Docker Compose** — контейнеризація

## Запуск локально

### 1. Клонувати репозиторій

```bash
git clone https://github.com/MStartsev/DevOps.git
cd DevOps
```

### 2. Створити `.env` файл

```bash
cp .env.example .env
```

Відредагувати `.env` та встановити власні значення:

```env
DJANGO_SECRET_KEY=your-very-secret-key-here
DJANGO_DEBUG=True
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
```

### 3. Запустити контейнери

```bash
docker-compose up -d
```

Після успішного запуску застосунок доступний за адресою: **http://localhost**

### 4. Зупинити і видалити контейнери

```bash
# Зупинити без видалення даних
docker-compose down

# Зупинити і видалити всі дані (включно з базою)
docker-compose down -v
```
