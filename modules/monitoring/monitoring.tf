# Prometheus + Grafana installed via Helm in the "monitoring" namespace

# Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name      = var.namespace
      ManagedBy = "Terraform"
    }
  }
}

# Prometheus
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.prometheus_chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  # Expose server via ClusterIP (access via port-forward)
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Enable Kubernetes service discovery
  set {
    name  = "server.global.scrape_interval"
    value = "1m"
  }

  # Persistent storage for metrics (uses gp2 StorageClass from EBS CSI driver)
  set {
    name  = "server.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "server.persistentVolume.size"
    value = "8Gi"
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = "gp2"
  }

  # Alertmanager — enabled by default
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # Node exporter — collects node-level metrics (CPU, RAM, disk)
  set {
    name  = "prometheus-node-exporter.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Grafana
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  namespace        = var.namespace
  create_namespace = false
  wait             = true
  timeout          = 600

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  # Expose via ClusterIP (access via port-forward)
  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  # Persistent storage for dashboards
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }

  set {
    name  = "persistence.storageClassName"
    value = "gp2"
  }

  # Auto-configure Prometheus as default data source
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.${var.namespace}.svc:80"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus,
  ]
}
