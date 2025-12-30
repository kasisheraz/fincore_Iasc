variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
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

variable "cloud_sql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
}

variable "cloud_sql_disk_size" {
  description = "Cloud SQL disk size"
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

variable "db_root_password" {
  description = "Root password"
  type        = string
  sensitive   = true
}

variable "db_app_password" {
  description = "App user password"
  type        = string
  sensitive   = true
}

variable "app_username" {
  description = "Application username"
  type        = string
}

variable "vpc_network" {
  description = "VPC network for private IP"
  type        = string
}

variable "private_subnet" {
  description = "Private subnet"
  type        = string
}