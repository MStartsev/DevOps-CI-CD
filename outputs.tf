# outputs.tf - root level outputs aggregated from all modules

# S3 Backend outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state"
  value       = module.s3_backend.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = module.s3_backend.bucket_arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name used for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# VPC output
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = module.vpc.nat_gateway_ip
}

# ECR outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

# EKS outputs
output "eks_cluster_name" {
  value = module.eks.cluster_name
}
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "eks_cluster_ca_certificate" {
  value     = module.eks.cluster_ca_certificate
  sensitive = true
}

# Jenkins outputs
output "jenkins_url" {
  description = "Jenkins external URL (LoadBalancer)"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password_secret" {
  description = "K8s secret name with Jenkins admin password"
  value       = module.jenkins.admin_password_secret
}

# Argo CD outputs
output "argocd_url" {
  description = "Argo CD external URL (LoadBalancer)"
  value       = module.argo_cd.argocd_url
}

output "argocd_admin_password_command" {
  description = "Command to retrieve initial Argo CD admin password"
  value       = module.argo_cd.admin_password_command
}
