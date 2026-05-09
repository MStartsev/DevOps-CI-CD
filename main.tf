# main.tf - root module
# Connects: s3-backend | vpc | ecr | eks | jenkins | argo_cd

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "mstartsev-terraform-state-2026"
  table_name  = "terraform-locks"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "devops_project"
  eks_cluster_name   = "devops_project"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "devops_project"
  scan_on_push = true
}

# Підключаємо модуль EKS
module "eks" {
  source             = "./modules/eks"
  cluster_name       = "devops_project"
  cluster_version    = "1.32"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_instance_type = "t3.medium"
  node_min_size      = 2
  node_max_size      = 4
  node_desired_size  = 2
}

# Uncomment for Phase 2 (after EKS is running)

# Підключаємо модуль Jenkins
module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  ecr_repo_url           = module.ecr.repository_url
  github_user            = var.github_user
  github_token           = var.github_token
  kaniko_role_arn        = module.eks.kaniko_role_arn
  postgres_password      = var.postgres_password
  django_secret_key      = var.django_secret_key
  app_namespace          = "django-app"

  depends_on = [module.eks]
}

# Підключаємо модуль Argo CD
module "argo_cd" {
  source                 = "./modules/argo_cd"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  repo_url               = "https://github.com/MStartsev/DevOps-CI-CD.git"
  target_branch          = "main"
  chart_path             = "charts/django-app"
  ecr_repo_url           = module.ecr.repository_url
  depends_on             = [module.eks]
  app_namespace          = "django-app"
  rds_endpoint           = module.rds.endpoint
  rds_database_name      = "appdb"
  rds_username           = "dbadmin"
}

# End Phase 2 block

# Підключаємо модуль RDS
module "rds" {
  source = "./modules/rds"

  project_name       = "devops-project"
  use_aurora         = false   # змініть на true для Aurora Cluster
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Engine
  engine                 = "postgres"
  engine_version         = "16.3"
  parameter_group_family = "postgres16"

  # Instance
  instance_class    = "db.t3.medium"
  allocated_storage = 20
  multi_az          = false

  # Credentials
  database_name = "appdb"
  username      = "dbadmin"
  password      = var.postgres_password   # вже оголошено в backend.tf

  # Lifecycle
  skip_final_snapshot = true
  deletion_protection = false
}