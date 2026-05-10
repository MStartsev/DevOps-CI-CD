terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    tls = {
      source = "hashicorp/tls",
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "mstartsev-terraform-state-2026"
    key            = "final-project/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "github_user" {
  description = "GitHub username for Jenkins credentials"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for Jenkins credentials"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password for django-secret K8s secret"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY for django-secret K8s secret"
  type        = string
  sensitive   = true
}
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}



data "aws_eks_cluster_auth" "main" {
  name = try(module.eks.cluster_name, "devops_project")
}

variable "eks_cluster_name" {
  description = "EKS cluster name for provider auth"
  type        = string
  default     = "devops_project"
}

provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, "https://localhost")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_ca_certificate), "")
  token                  = try(data.aws_eks_cluster_auth.main.token, "")
}

provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "https://localhost")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_ca_certificate), "")
    token                  = try(data.aws_eks_cluster_auth.main.token, "")
  }
}