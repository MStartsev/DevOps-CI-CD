# Standard RDS instance - created when use_aurora = false

resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  identifier        = "${var.project_name}-db"
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.database_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.main[0].name

  multi_az            = var.multi_az
  publicly_accessible = false
  storage_encrypted   = true

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  # Allow minor version auto-upgrades
  auto_minor_version_upgrade = true

  tags = {
    Name      = "${var.project_name}-db"
    ManagedBy = "Terraform"
    Type      = "rds"
  }
}
