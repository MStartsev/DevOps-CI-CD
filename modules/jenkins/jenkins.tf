# Jenkins installed via Helm into EKS

# Namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

# RBAC - Jenkins service account needs to create pods (Kubernetes agents)
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = var.namespace
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Secret for GitHub credentials (used in JCasC)
# Values come from root variables: TF_VAR_github_user / TF_VAR_github_token
resource "kubernetes_secret" "jenkins_github" {
  metadata {
    name      = "jenkins-github-secret"
    namespace = var.namespace
  }

  data = {
    username = var.github_user
    token    = var.github_token
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Jenkins Helm release
resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [file("${path.module}/values.yaml")]

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_cluster_role_binding.jenkins,
    kubernetes_secret.jenkins_github,
  ]
}

# Kaniko ServiceAccount з IRSA annotation
resource "kubernetes_service_account" "kaniko" {
  metadata {
    name      = "kaniko"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.kaniko_role_arn
    }
  }
  depends_on = [kubernetes_namespace.jenkins]
}

# django-secret у app namespace (автоматично - більше ручних команд!)
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_secret" "django_app" {
  metadata {
    name      = "django-secret"
    namespace = var.app_namespace
  }
  data = {
    POSTGRES_PASSWORD = var.postgres_password
    DJANGO_SECRET_KEY = var.django_secret_key
  }
  type       = "Opaque"
  depends_on = [kubernetes_namespace.app]
}