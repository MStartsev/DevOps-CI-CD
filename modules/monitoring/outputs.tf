output "prometheus_url" {
  description = "Port-forward command to access Prometheus UI"
  value       = "kubectl port-forward svc/prometheus-server 9090:80 -n ${var.namespace}"
}

output "grafana_url" {
  description = "Port-forward command to access Grafana UI"
  value       = "kubectl port-forward svc/grafana 3000:80 -n ${var.namespace}"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "grafana_datasource" {
  description = "Prometheus data source URL configured in Grafana"
  value       = "http://prometheus-server.${var.namespace}.svc:80"
}

output "namespace" {
  value = var.namespace
}
