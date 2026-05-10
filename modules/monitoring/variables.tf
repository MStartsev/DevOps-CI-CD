variable "namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Helm chart version for prometheus-community/prometheus"
  type        = string
  default     = "25.21.0"
}

variable "grafana_chart_version" {
  description = "Helm chart version for grafana/grafana"
  type        = string
  default     = "7.3.12"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "cluster_name" {
  description = "EKS cluster name (used for tags)"
  type        = string
}
