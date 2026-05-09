# Switch 
variable "use_aurora" {
  description = "true → Aurora Cluster + writer instance; false → single RDS instance"
  type        = bool
  default     = false
}

# Naming
variable "project_name" {
  description = "Project/environment prefix used in resource names"
  type        = string
}

# Network
variable "vpc_id" {
  description = "VPC ID where the database will be placed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB Subnet Group (minimum 2 AZs)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to port 5432/3306 (e.g. VPC CIDR)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Engine
variable "engine" {
  description = "Database engine: 'postgres' or 'mysql' (for RDS); 'aurora-postgresql' or 'aurora-mysql' (for Aurora)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "aurora-postgresql", "aurora-mysql"], var.engine)
    error_message = "engine must be one of: postgres, mysql, aurora-postgresql, aurora-mysql"
  }
}

variable "engine_version" {
  description = "Engine version (e.g. '16.3' for postgres, '8.0.36' for mysql, '16.3' for aurora-postgresql)"
  type        = string
  default     = "16.3"
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g. 'postgres16', 'mysql8.0', 'aurora-postgresql16', 'aurora-mysql8.0')"
  type        = string
  default     = "postgres16"
}

# Instance
variable "instance_class" {
  description = "DB instance class (e.g. 'db.t3.medium', 'db.r6g.large' for Aurora)"
  type        = string
  default     = "db.t3.medium"
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS instance (ignored for Aurora - always multi-AZ)"
  type        = bool
  default     = false
}

variable "allocated_storage" {
  description = "Allocated storage in GiB - RDS only (Aurora manages storage automatically)"
  type        = number
  default     = 20
}

variable "aurora_instance_count" {
  description = "Number of Aurora cluster instances (1 writer + N-1 readers)"
  type        = number
  default     = 1
}

# Credentials
variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password (use TF_VAR_* or a secrets manager in production)"
  type        = string
  sensitive   = true
}

# Lifecycle
variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false for production)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection (set true for production)"
  type        = bool
  default     = false
}

# Parameter group params
variable "db_parameters" {
  description = "List of DB parameter group parameters"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = [
    # Maximum connections - tune per instance class
    { name = "max_connections",  value = "200",     apply_method = "pending-reboot" },
    # Log all DDL and DML statements (PostgreSQL)
    { name = "log_statement",    value = "all",     apply_method = "immediate" },
    # Working memory per query sort/hash operation
    { name = "work_mem",         value = "16384",   apply_method = "immediate" },
  ]
}
