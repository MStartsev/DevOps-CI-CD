variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.3.11"
}

variable "repo_url" {
  description = "Git repository URL that Argo CD will watch"
  type        = string
}

variable "target_branch" {
  description = "Git branch to track"
  type        = string
  default     = "lesson-8-9--main"
}

variable "chart_path" {
  description = "Path to Helm chart inside the repository"
  type        = string
  default     = "charts/django-app"
}

variable "ecr_repo_url" {
  description = "ECR repository URL for the django image"
  type        = string
}

variable "app_namespace" {
  description = "Namespace where Argo CD will deploy the application"
  type        = string
  default     = "default"
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded EKS CA certificate"
  type        = string
}