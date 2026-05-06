output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate (for kubeconfig)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}

output "node_group_role_arn" {
  description = "ARN of the IAM role used by worker nodes"
  value       = aws_iam_role.eks_node_role.arn
}

output "cluster_security_group_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "kaniko_role_arn" {
  description = "IAM Role ARN for Kaniko IRSA"
  value       = aws_iam_role.kaniko.arn
}