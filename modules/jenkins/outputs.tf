output "jenkins_url" {
  description = "Jenkins LoadBalancer URL (may take 2-3 min to provision)"
  value       = "http://${helm_release.jenkins.name}.${var.namespace}.svc.cluster.local:8080"
}

output "admin_password_secret" {
  description = "Command to get Jenkins admin password"
  value       = "kubectl exec --namespace ${var.namespace} -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}

output "namespace" {
  value = var.namespace
}
