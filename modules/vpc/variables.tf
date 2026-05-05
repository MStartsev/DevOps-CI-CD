variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name tag prefix for all VPC resources"
  type        = string
  default     = "main-vpc"
}

variable "eks_cluster_name" {
  description = "EKS cluster name for subnet tagging"
  type        = string
  default     = ""
}