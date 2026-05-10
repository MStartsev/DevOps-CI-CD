# Lesson 10 - Створення гнучкого Terraform-модуля для баз даних

Повний CI/CD процес на AWS EKS:
**Jenkins** збирає образ => пушить у ECR => оновлює `values.yaml` у Git =>
**Argo CD** підхоплює зміни => синхронізує Helm chart у кластері.

Додано:
Модуль `rds` - Універсальна база даних, яка підіймає або **звичайну RDS instance**, або **Aurora Cluster**, залежно від прапора `use_aurora`.

---

## Структура проєкту

```
├── main.tf | backend.tf | outputs.tf
├── Jenkinsfile                         CI pipeline
├── modules/
│   ├── s3-backend/    S3 + DynamoDB
│   ├── vpc/           VPC, підмережі, IGW, NAT GW
│   ├── ecr/           ECR репозиторій
│   ├── eks/           EKS кластер + OIDC provider + EBS CSI driver
│   ├── rds/           Модуль для RDS
│   ├── jenkins/       Jenkins via Helm (Kaniko agent, JCasC)
│   └── argo_cd/       Argo CD via Helm + Application CRD
│       └── charts/    Helm chart: Application + Repository resources
├── charts/
│   └── django-app/    Django Helm chart (watched by Argo CD)
└── django-src/        Django source + Dockerfile
```

---

## Схема CI/CD

```
Developer push
│
▼
Jenkins Pipeline (Kaniko agent в EKS)
├── 1. git clone lesson-db-module
├── 2. kaniko build + push => ECR :<BUILD_NUMBER> (via IRSA)
├── 3. sed image.tag в charts/django-app/values.yaml
└── 4. git push => lesson-8-9--main

│ (Git change detected - polling або webhook)
▼
Argo CD (watches lesson-8-9--main / charts/django-app)
└── helm upgrade django-app => EKS (automated sync)
```

---

## Крок 0. Ініціалізація Remote State

> **Важливо:** S3 bucket і DynamoDB мають бути створені ДО ініціалізації backend.
> Перший раз запускати **без backend** (або з локальним стейтом), потім перенести стейт.

Скопіюй приклад і заповни своїми значеннями
`cp terraform.tfvars.example terraform.tfvars`
або задай через TF*VAR* змінні середовища (Крок 1)

### 0.1 Закоментуй backend у `backend.tf`

```hcl
terraform {
  # backend "s3" {
  #   bucket         = "your-name-terraform-state-2026"
  #   key            = "lesson-db-module/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}
```

### 0.2 Створи S3 bucket і DynamoDB

```bash
terraform init
terraform apply -target=module.s3_backend -auto-approve
```

### 0.3 Розкоментуй backend і мігруй state у S3

```hcl
terraform {
  backend "s3" {
    bucket         = "your-name-terraform-state-2026"
    key            = "lesson-db-module/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

```bash
terraform init -migrate-state
# Terraform запитає: "Do you want to copy existing state?" => yes
```

---

## Крок 1. Змінні середовища

Перед запуском Terraform задай секрети:

```bash
export TF_VAR_github_user="User_Name"
export TF_VAR_github_token="ghp_your_personal_access_token"
export TF_VAR_postgres_password="your_db_password"
export TF_VAR_django_secret_key="your_django_secret_key"
```

> **Windows PowerShell:**
>
> ```powershell
> $env:TF_VAR_github_user="User_Name"
> $env:TF_VAR_github_token="ghp_your_personal_access_token"
> $env:TF_VAR_postgres_password="your_db_password"
> $env:TF_VAR_django_secret_key="your_django_secret_key"
> ```

---

## Крок 2. Terraform - Phase 1: AWS інфраструктура

```bash
terraform init

# Phase 1: VPC, ECR, EKS
terraform apply \
  -target=module.vpc \
  -target=module.ecr \
  -target=module.eks \
  -auto-approve
```

Після завершення (~10 хв) отримай kubeconfig:

```bash
aws eks update-kubeconfig --name devops_project --region us-west-2
kubectl get nodes   # має показати 2 ноди зі статусом Ready
```

---

## Крок 3. Terraform - Phase 2: Jenkins + Argo CD

```bash
# Повне розгортання (Jenkins + Argo CD через Helm)
terraform apply -auto-approve

# Перед перевіркою Jenkins переконайся що ноди Ready
kubectl get nodes

# Перевірити що Jenkins запустився (2/2 Running)
kubectl get pods -n jenkins -w
# Зачекай поки jenkins-0 покаже 2/2 Running

# Перевірити що Argo CD запустився
kubectl get pods -n argocd
# Всі поди мають бути 1/1 Running
```

> Kaniko авторизується в ECR автоматично через **IRSA** (IAM Roles for Service Accounts) - ручне створення Docker secret не потрібне.

---

## Крок 4. Перевірка Jenkins

```bash
# Зовнішній URL Jenkins
kubectl get svc jenkins -n jenkins
# Відкрити порт 8080 для доступу до Jenkins UI
# AWS Console: EC2 => Security Groups => вузли EKS => Inbound Rules
# Додати: TCP 8080, Source: 0.0.0.0/0 або
# Знайди Security Group нод
NODE_SG=$(aws eks describe-cluster --name devops_project \
  --region us-west-2 \
  --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
  --output text)

# Відкрий порт 8080
aws ec2 authorize-security-group-ingress \
  --group-id $NODE_SG \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region us-west-2

# Пароль адміна
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins \
  -- /bin/cat /run/secrets/additional/chart-admin-password
```

### Налаштування Pipeline у UI

1. **New Item** => введи назву `django-pipeline` => вибери **Pipeline** => OK
2. Прокрути до секції **Pipeline**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/MStartsev/DevOps-CI-CD.git`
   - Credentials: `github-credentials`
   - Branch: `*/lesson-db-module`
   - Script Path: `Jenkinsfile`
3. **Save** => **Build Now**

Після успішного запуску побачиш 3 зелені стадії:

- `Build & Push Docker Image (Kaniko)`
- `Update Helm values.yaml & Push to lesson-8-9--main`

---

## Крок 5. Перевірка Argo CD

```bash
# Зовнішній URL
kubectl get svc argocd-server -n argocd

# Пароль адміна (Linux/macOS)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Пароль адміна (Windows PowerShell)
$encoded = kubectl -n argocd get secret argocd-initial-admin-secret `
  -o jsonpath='{.data.password}'
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))
```

Відкрий `http://<EXTERNAL-IP>` => логін `admin` => пароль з команди вище.

Після входу: Application `django-app` => статус **Synced / Healthy**.  
Після кожного Jenkins build Argo CD автоматично застосовує новий тег образу.

---

## Крок 6. Перевірка Django застосунку

```bash
# Зовнішній URL Django
kubectl get svc django-app-service -n django-app

# Статус подів
kubectl get pods -n django-app
# Має бути:
# django-app-django-xxx      1/1   Running
# django-app-postgres-0      1/1   Running
```

Відкрий у браузері: `http://<EXTERNAL-IP>/admin/login/`

---

## Видалення інфраструктури

```bash
# Спочатку прибрати K8s LoadBalancer ресурси
helm uninstall django-app -n django-app
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
kubectl delete namespace django-app

# Потім знищити всю AWS інфраструктуру
terraform destroy -auto-approve
```

> Обов'язково видалити Helm releases перед `terraform destroy` - інакше AWS LoadBalancer залишиться і заблокує видалення VPC.

---

## Опис модулів

### `modules/eks/aws_ebs_csi_driver.tf`

EBS CSI Driver як EKS managed add-on. Використовує OIDC + IRSA для безпечного доступу до AWS API. Створює StorageClass `gp2` як default - потрібна для Jenkins PVC та PostgreSQL PVC.

### `modules/jenkins`

Jenkins встановлюється через Helm chart `jenkins/jenkins` версії `5.8.17` з образом `jenkins/jenkins:2.492.3-lts-jdk17`. Включає:

- Kubernetes plugin для dynamic agents (Kaniko + Git контейнери)
- Kaniko авторизується в ECR через IRSA (`kaniko` ServiceAccount)
- JCasC (Configuration as Code) - GitHub credentials з K8s Secret
- RBAC ClusterRoleBinding - Jenkins може створювати pod-агенти

### `modules/argo_cd`

Argo CD встановлюється через Helm chart `argoproj/argo-cd`. Вкладений Helm chart (`charts/`) розгортає:

- `Application` CRD - вказує на `charts/django-app` у гілці `lesson-8-9--main`
- `Repository` Secret - реєструє GitHub репозиторій в Argo CD

### `charts/django-app`

Helm chart для Django застосунку. Містить:

- `Deployment` з `initContainer` (чекає на готовність PostgreSQL)
- `StatefulSet` для PostgreSQL з EBS PVC (`subPath: pgdata`)
- `HorizontalPodAutoscaler` (2-6 реплік за CPU)
- `ConfigMap` зі змінними середовища
- `Service` типу LoadBalancer (AWS NLB)

---

## Модуль `rds` - Універсальна база даних

### Опис

Модуль підіймає або **звичайну RDS instance**, або **Aurora Cluster** - залежно від прапора `use_aurora`.

В обох випадках автоматично створюється:

- `aws_db_subnet_group` - розміщує БД у приватних підмережах
- `aws_security_group` - дозволяє вхідний трафік лише з дозволених CIDR
- Parameter Group з параметрами `max_connections`, `log_statement`, `work_mem`

---

### Приклад використання

```hcl
# Варіант A: звичайна RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  project_name       = "myproject"
  use_aurora         = false
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine                 = "postgres"
  engine_version         = "16.13"
  parameter_group_family = "postgres16"

  instance_class    = "db.t3.medium"
  allocated_storage = 20
  multi_az          = false

  database_name = "appdb"
  username      = "dbadmin"
  password      = var.db_password
}

# Варіант B: Aurora PostgreSQL кластер
module "rds" {
  source = "./modules/rds"

  project_name       = "myproject"
  use_aurora         = true          # <= єдина зміна для Aurora
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  engine                 = "aurora-postgresql"
  engine_version         = "16.13"
  parameter_group_family = "aurora-postgresql16"

  instance_class        = "db.r6g.large"
  aurora_instance_count = 2          # 1 writer + 1 reader

  database_name = "appdb"
  username      = "dbadmin"
  password      = var.db_password
}
```

---

### Опис змінних

| Змінна                   | Тип          | За замовчуванням    | Опис                                                                                           |
| ------------------------ | ------------ | ------------------- | ---------------------------------------------------------------------------------------------- |
| `use_aurora`             | bool         | `false`             | `true` => Aurora Cluster; `false` => RDS instance                                              |
| `project_name`           | string       | -                   | Префікс для імен всіх ресурсів                                                                 |
| `vpc_id`                 | string       | -                   | ID VPC                                                                                         |
| `private_subnet_ids`     | list(string) | -                   | Приватні підмережі (мінімум 2 AZ)                                                              |
| `allowed_cidr_blocks`    | list(string) | `["10.0.0.0/16"]`   | CIDR для доступу до порту БД                                                                   |
| `engine`                 | string       | `"postgres"`        | `postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql`                                       |
| `engine_version`         | string       | `"16.13"`           | Версія engine (напр. `"16.13"`, `"8.0.36"`)                                                    |
| `parameter_group_family` | string       | `"postgres16"`      | Сімейство parameter group (`postgres16`, `mysql8.0`, `aurora-postgresql16`, `aurora-mysql8.0`) |
| `instance_class`         | string       | `"db.t3.medium"`    | Клас інстансу (`db.t3.medium`, `db.r6g.large` тощо)                                            |
| `multi_az`               | bool         | `false`             | Multi-AZ для RDS (Aurora завжди multi-AZ)                                                      |
| `allocated_storage`      | number       | `20`                | Розмір сховища в ГіБ (тільки для RDS)                                                          |
| `aurora_instance_count`  | number       | `1`                 | Кількість Aurora інстансів (1 writer + N-1 readers)                                            |
| `database_name`          | string       | `"appdb"`           | Ім'я початкової БД                                                                             |
| `username`               | string       | `"dbadmin"`         | Master username                                                                                |
| `password`               | string       | -                   | Master password (`sensitive`)                                                                  |
| `skip_final_snapshot`    | bool         | `true`              | Пропустити snapshot при destroy (`false` для продакшн)                                         |
| `deletion_protection`    | bool         | `false`             | Захист від видалення (`true` для продакшн)                                                     |
| `db_parameters`          | list(object) | PostgreSQL defaults | Параметри parameter group                                                                      |

---

### Як змінити тип БД, engine або клас інстансу

**Перемикач RDS => Aurora:**

```hcl
use_aurora             = true
engine                 = "aurora-postgresql"
parameter_group_family = "aurora-postgresql16"
instance_class         = "db.r6g.large"   # Aurora потребує r-серії
aurora_instance_count  = 2                # writer + 1 reader
```

**MySQL замість PostgreSQL:**

```hcl
engine                 = "mysql"
engine_version         = "8.0.36"
parameter_group_family = "mysql8.0"
# db_parameters потрібно переоголосити - log_statement і work_mem є тільки у PostgreSQL:
db_parameters = [
  { name = "max_connections", value = "200", apply_method = "pending-reboot" },
  { name = "slow_query_log",  value = "1",   apply_method = "immediate" },
]
```

**Продакшн-налаштування:**

```hcl
instance_class      = "db.r6g.xlarge"
multi_az            = true    # RDS; Aurora - завжди multi-AZ
skip_final_snapshot = false
deletion_protection = true
aurora_instance_count = 3     # 1 writer + 2 readers
```
