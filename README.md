# Lesson 7 - Kubernetes on EKS + Helm Chart

Django-застосунок на Amazon EKS, розгорнутий через Helm. Terraform управляє всією інфраструктурою.

---

## Структура проєкту

```
├── main.tf | backend.tf | outputs.tf
├── modules/
│   ├── s3-backend/    S3 bucket + DynamoDB (state + lock)
│   ├── vpc/           VPC, публічні/приватні підмережі, IGW, NAT GW
│   ├── ecr/           ECR репозиторій для Django-образу
│   └── eks/           EKS кластер + Managed Node Group + IAM ролі
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── configmap.yaml    env vars з lesson-4
            ├── deployment.yaml   Django pods (ECR image + ConfigMap)
            ├── service.yaml      LoadBalancer (AWS NLB)
            └── hpa.yaml          HPA: 2-6 pods при CPU > 70%
```

---

## Крок 1. Terraform: розгортання інфраструктури

### Bootstrap (перший раз)

У `main.tf` та `backend.tf` знайдіть і замініть:

```
bucket_name = "your-name-terraform-state"
bucket      = "your-name-terraform-state"
```

S3 bucket name має бути глобально унікальним. Формат: `<ім'я>-terraform-state-2026`.

```bash
# 1. Закоментуйте блок backend "s3" у backend.tf
# 2. Створіть S3 та DynamoDB
terraform init
terraform apply -target=module.s3_backend

# 3. Розкоментуйте backend "s3", перенесіть стейт
terraform init -migrate-state

# 4. Розгорніть решту інфраструктури
terraform apply
```

### Отримати kubeconfig

```bash
aws eks update-kubeconfig \
  --name lesson-7 \
  --region us-west-2

kubectl get nodes   # має показати 2 ноди
```

---

## Крок 2. ECR: push Docker-образу

```bash
# 1. Отримайте URL репозиторію
$ECR_URL = terraform output -raw ecr_repository_url
$ECR_REGISTRY= echo $ECR_URL | cut -d'/' -f1

# 2. Автентифікація в ECR
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin $ECR_REGISTRY

# 3. Збудуйте образ (Dockerfile у django-src/)
# Важливо: entrypoint.sh має Unix line endings (LF).
# Dockerfile містить sed -i 's/\r//' для автоматичної конвертації з CRLF.
docker build -t lesson-7 ./django-src

docker tag lesson-7:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

---

## Крок 3. PostgreSQL: розгортання бази даних

PostgreSQL розгортається у кластері через Helm chart від Bitnami.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install postgres bitnami/postgresql \
  --set auth.database=mydb \
  --set auth.username=myuser \
  --set auth.password=your_strong_password_here \
  --set primary.persistence.enabled=false

# Перевірка - postgres-postgresql-0 має бути 1/1 Running
kubectl get pods | grep postgres
kubectl get svc  | grep postgres
# Сервіс: postgres-postgresql:5432
```

> `persistence.enabled=false` - дані губляться при рестарті pod.
> Для продакшну потрібен EBS CSI driver та StorageClass.

---

## Крок 4. Helm: розгортання Django

### Підготовка Secret

```bash
# 1. Скопіюйте та заповніть .env
cp .env.example .env
# Відредагуйте .env - вставте реальні значення
# ВАЖЛИВО: POSTGRES_HOST=postgres-postgresql (ім'я K8s сервісу)

# 2. Створіть Secret
kubectl create secret generic django-secret \
  --from-env-file=.env --namespace default \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl get secret django-secret
```

### Встановлення чарту

```bash
# Linux / macOS
ECR_URL=$(terraform output -raw ecr_repository_url)

helm upgrade --install django-app ./charts/django-app \
  --namespace default \
  --values ./charts/django-app/values.yaml \
  --set image.repository="$ECR_URL"
```

```powershell
# Windows (PowerShell)
$ECR_URL = terraform output -raw ecr_repository_url

helm upgrade --install django-app ./charts/django-app `
  --namespace default `
  --values ./charts/django-app/values.yaml `
  --set image.repository="$ECR_URL"
```

### Перевірка

```bash
kubectl get pods      # 2 pods - 1/1 Running
kubectl get svc       # django-app-service - EXTERNAL-IP присвоєно
kubectl get hpa       # cpu: <x>%/70%, min 2, max 6
kubectl get configmap # django-app-config

# Публічна адреса застосунку
kubectl get svc django-app-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# Відкрити: http://<hostname>/admin/
```

---

## Helm команди

```bash
# Встановлення / оновлення
helm upgrade --install django-app ./charts/django-app \
  --set image.repository="$ECR_URL" \
  --set image.tag="latest"

# Стан релізу
helm status django-app
helm get values django-app

# Видалення (перед terraform destroy!)
helm uninstall django-app
helm uninstall postgres
```

---

## Terraform команди

```bash
terraform init      # ініціалізація провайдерів і модулів
terraform plan      # перегляд змін без застосування
terraform apply     # застосування інфраструктури
terraform destroy   # знищення (спочатку: helm uninstall django-app && helm uninstall postgres)
```

---

## Опис модулів

### `s3-backend`

S3 bucket (versioning + AES-256 + block public access) + DynamoDB (LockID, PAY_PER_REQUEST, PITR).

### `vpc`

VPC `10.0.0.0/16` => 3 публічні + 3 приватні підмережі по одній на AZ.
IGW для публічних, NAT GW для приватних. Окремі Route Tables.
Subnet tags `kubernetes.io/role/elb` і `kubernetes.io/role/internal-elb` для AWS Load Balancer.

### `ecr`

Приватний репозиторій: `scan_on_push = true`, lifecycle policy (видаляє untagged за 1 день, зберігає 10 tagged), repository policy на поточний account.

### `eks`

EKS 1.29: control plane у multi-AZ, Managed Node Group у **приватних** підмережах (t3.medium, 2-4 nodes), rolling update. IAM ролі: cluster role + node role (ECR read + CNI + worker).

### Helm chart `django-app`

| Ресурс     | Опис                                                                                  |
| ---------- | ------------------------------------------------------------------------------------- |
| ConfigMap  | env vars з lesson-4: `DJANGO_*`, `POSTGRES_*`                                         |
| Deployment | 2 replicas, ECR image, `envFrom: configMapRef + secretRef`, liveness/readiness probes |
| Service    | LoadBalancer (AWS NLB), port 80 => 8000                                               |
| HPA        | min 2 / max 6 pods, CPU threshold 70%, anti-flapping policies                         |

---
