# Cloud SQL Module - Essential configuration for database permissions

resource "google_sql_database_instance" "main" {
  name             = "${var.name_prefix}-${var.environment}-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier                        = var.cloud_sql_tier
    disk_size                   = var.cloud_sql_disk_size
    disk_type                   = "PD_SSD"
    deletion_protection_enabled = var.delete_protection_enabled

    backup_configuration {
      enabled            = var.cloud_sql_backup_enabled
      start_time         = "02:00"
      binary_log_enabled = var.environment == "prod"
      backup_retention_settings {
        retained_backups = var.cloud_sql_backup_retention_days
      }
    }

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = var.cloud_sql_require_ssl

      # Allow GitHub Actions runners to connect
      # Note: For better security, restrict this to specific IPs in production
      authorized_networks {
        name  = "github-actions"
        value = "0.0.0.0/0"
      }
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "lower_case_table_names"
      value = "1"
    }
  }

  deletion_protection = var.delete_protection_enabled
}

resource "google_sql_database" "main" {
  name      = var.database_name
  instance  = google_sql_database_instance.main.name
  charset   = "utf8mb4"
  collation = "utf8mb4_0900_ai_ci" # MySQL 8.0 accent-insensitive, case-insensitive collation
}

resource "google_sql_user" "root" {
  name     = "root"
  instance = google_sql_database_instance.main.name
  password = var.db_root_password
}

resource "google_sql_user" "app" {
  name     = var.app_username
  instance = google_sql_database_instance.main.name
  password = var.db_app_password
}