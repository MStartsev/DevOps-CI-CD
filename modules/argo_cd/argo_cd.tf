# Argo CD installed via Helm + Application pointing to django-app Helm chart
# Watches: branch = main  (де Jenkins пушить оновлений values.yaml)

# Namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Argo CD Helm release
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [file("${path.module}/values.yaml")]

  depends_on = [kubernetes_namespace.argocd]
}

# Argo CD Applications Helm chart - creates Application + Repository CRDs
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = var.namespace
  wait      = false   # CRDs may need a moment to register

  set {
    name  = "repoUrl"
    value = var.repo_url
  }

  set {
    name  = "targetBranch"
    value = var.target_branch
  }

  set {
    name  = "chartPath"
    value = var.chart_path
  }

  set {
    name  = "appNamespace"
    value = var.app_namespace
  }

  set {
    name  = "image.repository"
    value = var.ecr_repo_url
  }

  depends_on = [helm_release.argocd]
}
