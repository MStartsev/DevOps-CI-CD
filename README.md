# Lesson 5 - Terraform Infrastructure on AWS

Terraform-модульна інфраструктура AWS: **S3 remote state + DynamoDB lock | VPC | ECR**.

---

## Структура проєкту

```
lesson-5/
├── main.tf          # Підключення всіх модулів
├── backend.tf       # Remote state: S3 + DynamoDB + provider AWS
├── outputs.tf       # Агреговані виходи з усіх модулів
│
└── modules/
    ├── s3-backend/  # S3 bucket + DynamoDB table
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/         # VPC, підмережі, IGW, NAT GW, Route Tables
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecr/         # ECR репозиторій + lifecycle policy + repository policy
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Попередні вимоги

| Інструмент      | Версія                            |
| --------------- | --------------------------------- |
| Terraform       | >= 1.9.0                          |
| AWS CLI         | >= 2.x                            |
| AWS credentials | `~/.aws/credentials` або env vars |

---

## Налаштування перед першим запуском

### 1. Замініть `bucket_name` на унікальне ім'я

У `main.tf` та `backend.tf` знайдіть рядки:

```
bucket_name = "your-name-terraform-state"
bucket      = "your-name-terraform-state"
```

Замініть `your-name-terraform-state` на ваше ім'я (S3 bucket name - глобально унікальний).

### 2. Перший запуск — bootstrap

> **Важливо:** S3 bucket і DynamoDB мають бути створені ДО ініціалізації backend.
> Перший раз запускати **без backend** (або з локальним стейтом), потім перенести стейт.

```bash
# Крок 1: закоментуйте backend "s3" блок у backend.tf
# Крок 2:
terraform init
terraform apply -target=module.s3_backend

# Крок 3: розкоментуйте backend "s3" блок
# Крок 4: перенесіть стейт у S3
terraform init -migrate-state
```

---

## Команди

```bash
# Ініціалізація (завантаження провайдерів і модулів)
terraform init

# Перегляд плану змін без застосування
terraform plan

# Застосування інфраструктури
terraform apply

# Застосування без підтвердження (CI/CD)
terraform apply -auto-approve

# Знищення всіх ресурсів
terraform destroy
```

---

## Опис модулів

### `s3-backend`

Створює ресурси для зберігання Terraform state файлів:

- **S3 bucket** - versioning enabled, AES-256 encryption, public access blocked
- **DynamoDB table** - `LockID` hash key, `PAY_PER_REQUEST` billing, PITR enabled

Блокування через DynamoDB запобігає одночасним змінам стейту кількома розробниками (race condition).

### `vpc`

Мережева інфраструктура:

- **VPC** - CIDR `10.0.0.0/16`, DNS support та hostnames увімкнено
- **3 публічні підмережі** - `10.0.1-3.0/24`, по одній у кожній AZ, `map_public_ip_on_launch = true`
- **3 приватні підмережі** - `10.0.4-6.0/24`, без прямого доступу з інтернету
- **Internet Gateway** - вихід у інтернет для публічних підмереж
- **NAT Gateway** - вихідний трафік для приватних підмереж (один для dev, для prod - по одному на AZ)
- **Route Tables** - окремі таблиці маршрутизації для публічних та приватних підмереж

### `ecr`

Elastic Container Registry:

- **Репозиторій** - `scan_on_push = true` (автоматичне сканування CVE при push)
- **Lifecycle policy** - untagged images видаляються через 1 день; зберігаються останні 10 tagged images з префіксом `v`
- **Repository policy** - повний доступ для поточного AWS account

---

## Виходи (outputs)

```
s3_bucket_name       => ім'я S3 bucket
s3_bucket_arn        => ARN S3 bucket
dynamodb_table_name  => ім'я DynamoDB таблиці
vpc_id               => ID VPC
public_subnet_ids    => список ID публічних підмереж
private_subnet_ids   => список ID приватних підмереж
nat_gateway_ip       => Elastic IP NAT Gateway
ecr_repository_url   => URL для docker push/pull
ecr_repository_arn   => ARN ECR репозиторію
```

---

## Git workflow

```bash
git checkout -b lesson-5
git add .
git commit -m "Add Terraform modules for S3, VPC, and ECR"
git push origin lesson-5
```
