output "endpoint" {
  description = "Primary connection endpoint (writer for Aurora, instance for RDS)"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].endpoint : ""
  ) : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].address : ""
  )
}

output "reader_endpoint" {
  description = "Aurora read-only endpoint (empty for RDS)"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].reader_endpoint : ""
  ) : ""
}

output "port" {
  description = "Database port"
  value       = local.db_port
}

output "database_name" {
  description = "Name of the initial database"
  value       = var.database_name
}

output "username" {
  description = "Master username"
  value       = var.username
  sensitive   = true
}

output "security_group_id" {
  description = "Security Group ID attached to the database"
  value       = aws_security_group.db.id
}

output "subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.main.name
}

output "type" {
  description = "Database type: 'aurora' or 'rds'"
  value       = var.use_aurora ? "aurora" : "rds"
}
