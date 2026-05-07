variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded EKS CA certificate"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Jenkins Helm chart version"
  type        = string
  default     = "5.1.17"
}

variable "ecr_repo_url" {
  description = "ECR repository URL (used in Jenkins pipeline config)"
  type        = string
}

variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "github_user" {
  description = "GitHub username injected into Jenkins credentials secret"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token injected into Jenkins credentials secret"
  type        = string
  sensitive   = true
}

variable "kaniko_role_arn" {
  description = "IAM Role ARN for Kaniko IRSA (ECR push without docker secret)"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password for django-secret"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY for django-secret"
  type        = string
  sensitive   = true
}

variable "app_namespace" {
  description = "Namespace where django-app runs (for django-secret)"
  type        = string
  default     = "default"
}