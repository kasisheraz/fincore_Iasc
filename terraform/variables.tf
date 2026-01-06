# Fincore Infrastructure Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "project-07a61357-b791-4255-a9e"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (npe, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "app_username" {
  description = "Application username"
  type        = string
}

variable "cloud_sql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
}

variable "cloud_sql_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
}

variable "cloud_sql_backup_enabled" {
  description = "Enable Cloud SQL backups"
  type        = bool
}

variable "cloud_sql_backup_retention_days" {
  description = "Backup retention days"
  type        = number
}

variable "cloud_sql_require_ssl" {
  description = "Require SSL connections"
  type        = bool
}

variable "delete_protection_enabled" {
  description = "Enable deletion protection"
  type        = bool
}

variable "app_privileges" {
  description = "Database privileges for application user"
  type        = list(string)
}

variable "create_admin_user" {
  description = "Create admin user for schema management"
  type        = bool
}