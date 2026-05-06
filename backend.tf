terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mstartsev-terraform-state-2026"
    key            = "lesson-8-9/terraform.tfstate"
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