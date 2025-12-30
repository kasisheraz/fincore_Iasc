# Database Permissions Module Variables

variable "database_endpoint" {
  description = "Database connection endpoint (host:port)"
  type        = string
}

variable "admin_username" {
  description = "Database admin username"
  type        = string
  default     = "root"
}

variable "admin_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the database to grant permissions on"
  type        = string
  default     = "my_auth_db"
}

variable "app_username" {
  description = "Application database username"
  type        = string
  default     = "fincore_app"
}

variable "app_password" {
  description = "Application database password"
  type        = string
  sensitive   = true
}

variable "app_privileges" {
  description = "Privileges to grant to application user"
  type        = list(string)
  default = [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ]

  validation {
    condition = alltrue([
      for privilege in var.app_privileges : contains([
        "ALL PRIVILEGES", "SELECT", "INSERT", "UPDATE", "DELETE",
        "CREATE", "DROP", "INDEX", "ALTER", "CREATE TEMPORARY TABLES",
        "LOCK TABLES", "EXECUTE", "CREATE VIEW", "SHOW VIEW",
        "CREATE ROUTINE", "ALTER ROUTINE", "EVENT", "TRIGGER"
      ], privilege)
    ])
    error_message = "Invalid privilege specified. Must be valid MySQL privilege."
  }
}

variable "admin_privileges" {
  description = "Administrative privileges for schema management (migrations, etc.)"
  type        = list(string)
  default = [
    "SELECT", "INSERT", "UPDATE", "DELETE",
    "CREATE", "DROP", "INDEX", "ALTER",
    "CREATE TEMPORARY TABLES", "LOCK TABLES"
  ]
}

variable "create_admin_user" {
  description = "Create administrative user for schema migrations"
  type        = bool
  default     = false
}

variable "app_admin_username" {
  description = "Administrative database username for migrations"
  type        = string
  default     = "fincore_admin"
}

variable "app_admin_password" {
  description = "Administrative database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "require_ssl" {
  description = "Require SSL connections to database"
  type        = bool
  default     = true
}

variable "create_readonly_user" {
  description = "Create a read-only user for monitoring/reporting"
  type        = bool
  default     = false
}

variable "readonly_username" {
  description = "Read-only database username"
  type        = string
  default     = "fincore_readonly"
}

variable "readonly_password" {
  description = "Read-only database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "environment" {
  description = "Environment (npe, prod, etc.)"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}