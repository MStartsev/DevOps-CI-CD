# Lesson 8-9 - CI/CD: Jenkins + Argo CD + Helm + Terraform

Повний CI/CD процес на AWS EKS:
**Jenkins** збирає образ => пушить у ECR => оновлює `values.yaml` у Git =>
**Argo CD** підхоплює зміни => синхронізує Helm chart у кластері.

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
├── 1. git clone lesson-8-9
├── 2. kaniko build + push => ECR :<BUILD_NUMBER> (via IRSA)
├── 3. sed image.tag в charts/django-app/values.yaml
└── 4. git push => lesson-8-9--main

│ (Git change detected - polling або webhook)
▼
Argo CD (watches lesson-8-9--main / charts/django-app)
└── helm upgrade django-app => EKS (automated sync)
```

---

## Крок 1. Підготовка змінних середовища

Перед запуском Terraform задайте секрети через змінні середовища:

```bash
export TF_VAR_github_user="MStartsev"
export TF_VAR_github_token="ghp_your_personal_access_token"
export TF_VAR_postgres_password="your_db_password"
export TF_VAR_django_secret_key="your_django_secret"
```

---

## Крок 2. Terraform - Phase 1: AWS інфраструктура

Застосовуємо інфраструктуру у два етапи, оскільки Jenkins та Argo CD залежать від готового EKS кластера.

```bash
terraform init

# Phase 1: Створення базової інфраструктури (VPC, ECR, EKS)
terraform apply \
  -target=module.vpc \
  -target=module.ecr \
  -target=module.eks
```

```bash
# Отримати kubeconfig
aws eks update-kubeconfig --name devops_project --region us-west-2
kubectl get nodes   # має показати 2 ноди Ready
```

---

## Крок 3. Terraform - Phase 2: Jenkins + Argo CD

Після готовності EKS кластера запускаємо встановлення Helm чартів:

```bash
# Phase 2: Повне розгортання
terraform apply
```

*(Kaniko тепер автоматично використовує IRSA (IAM Roles for Service Accounts) для авторизації в ECR, ручне створення secret більше не потрібне).*

---

## Крок 4. Перевірка Jenkins

```bash
# Зовнішній URL Jenkins
kubectl get svc jenkins -n jenkins
# Відкрити: http://<EXTERNAL-IP>:8080

# Пароль адміна
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins \
  -- /bin/cat /run/secrets/additional/chart-admin-password
```

Налаштувати pipeline у UI:

1. **New Item** => Pipeline
2. Pipeline Definition: **Pipeline script from SCM**
3. SCM: Git, URL: `https://github.com/MStartsev/DevOps-CI-CD.git`
4. Branch: `lesson-8-9`, Script Path: `Jenkinsfile`
5. **Build Now** => перевірити всі 3 stages

---

## Крок 5. Перевірка Argo CD

```bash
# Зовнішній URL
kubectl get svc argocd-server -n argocd

# Початковий пароль адміна
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Відкрити: http://<EXTERNAL-IP>
# Login: admin / <пароль вище>
```

Після входу: Application `django-app` => статус **Synced / Healthy**.
Після кожного Jenkins build - Argo CD автоматично застосовує новий тег.

---

## Terraform команди

```bash
terraform init
terraform plan
terraform apply

# Перед знищенням - прибрати K8s ресурси щоб AWS не залишив LoadBalancer:
helm uninstall django-app -n default
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
terraform destroy
```

---

## Опис нових модулів

### `modules/eks/aws_ebs_csi_driver.tf`

EBS CSI Driver як EKS managed add-on. Використовує OIDC IRSA для безпечного доступу до AWS API. Створює StorageClass `gp2` як default - потрібна для Jenkins PVC.

### `modules/jenkins`

Jenkins встановлюється через Helm chart `jenkins/jenkins`. Включає:

- Kubernetes plugin для dynamic agents (Kaniko + Git контейнери)
- Kaniko авторизується в ECR через IRSA (`kaniko` ServiceAccount)
- JCasC (Jenkins Configuration as Code) - credentials з K8s Secret
- RBAC ClusterRoleBinding - Jenkins може створювати pod-агенти

### `modules/argo_cd`

Argo CD встановлюється через Helm chart `argoproj/argo-cd`. Включає вкладений Helm chart (`charts/`) який розгортає:

- `Application` CRD - вказує на `charts/django-app` у `lesson-8-9`
- `Repository` Secret - реєструє GitHub репозиторій

---

