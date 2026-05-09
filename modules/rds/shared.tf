# Resources created regardless of use_aurora:
#   - DB Subnet Group
#   - Security Group
#   - Parameter Group (db for RDS, cluster for Aurora)

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Subnet group for ${var.project_name} database"

  tags = {
    Name      = "${var.project_name}-db-subnet-group"
    ManagedBy = "Terraform"
  }
}

# Security Group
locals {
  # PostgreSQL uses port 5432, MySQL uses port 3306
  db_port = contains(["postgres", "aurora-postgresql"], var.engine) ? 5432 : 3306
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Allow inbound DB traffic from allowed CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB port from allowed CIDRs"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-db-sg"
    ManagedBy = "Terraform"
  }
}

# Parameter Group - RDS instance (use_aurora = false)
resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.project_name}-db-pg"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.project_name} RDS instance"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name      = "${var.project_name}-db-pg"
    ManagedBy = "Terraform"
  }
}

# Parameter Group - Aurora cluster (use_aurora = true)
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.project_name}-aurora-cpg"
  family      = var.parameter_group_family
  description = "Cluster parameter group for ${var.project_name} Aurora"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name      = "${var.project_name}-aurora-cpg"
    ManagedBy = "Terraform"
  }
}
