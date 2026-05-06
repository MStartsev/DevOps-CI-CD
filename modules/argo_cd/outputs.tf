output "argocd_url" {
  description = "Argo CD UI - get external IP: kubectl get svc argocd-server -n argocd"
  value       = "kubectl get svc argocd-server -n ${var.namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_command" {
  description = "Command to retrieve initial Argo CD admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "namespace" {
  value = var.namespace
}
