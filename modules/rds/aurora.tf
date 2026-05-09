# Aurora Cluster + writer instance - created when use_aurora = true

resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.project_name}-aurora"
  engine             = var.engine
  engine_version     = var.engine_version

  database_name   = var.database_name
  master_username = var.username
  master_password = var.password

  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name

  storage_encrypted   = true
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  tags = {
    Name      = "${var.project_name}-aurora"
    ManagedBy = "Terraform"
    Type      = "aurora"
  }
}

resource "aws_rds_cluster_instance" "main" {
  # aurora_instance_count controls the number of instances (1 writer + optional readers)
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.project_name}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  publicly_accessible    = false
  auto_minor_version_upgrade = true

  tags = {
    Name      = "${var.project_name}-aurora-${count.index == 0 ? "writer" : "reader-${count.index}"}"
    ManagedBy = "Terraform"
    Role      = count.index == 0 ? "writer" : "reader"
  }
}
