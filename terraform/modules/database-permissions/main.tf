# Database Permissions Module
# Manages database users, permissions, and access control

terraform {
  required_providers {
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }
}

# Create application database user
resource "mysql_user" "fincore_app" {
  user               = var.app_username
  host               = "%"
  plaintext_password = var.app_password
}

# Create application database user for Cloud SQL Proxy connections
resource "mysql_user" "fincore_app_proxy" {
  user               = var.app_username
  host               = "cloudsqlproxy~%"
  plaintext_password = var.app_password
}

# Grant privileges to standard connection
resource "mysql_grant" "fincore_app_privileges" {
  user       = mysql_user.fincore_app.user
  host       = mysql_user.fincore_app.host
  database   = var.database_name
  privileges = var.app_privileges

  depends_on = [mysql_user.fincore_app]
}

# Grant privileges to Cloud SQL Proxy connection
resource "mysql_grant" "fincore_app_proxy_privileges" {
  user       = mysql_user.fincore_app_proxy.user
  host       = mysql_user.fincore_app_proxy.host
  database   = var.database_name
  privileges = var.app_privileges

  depends_on = [mysql_user.fincore_app_proxy]
}

# Create administrative user for schema management (optional)
resource "mysql_user" "fincore_admin" {
  count              = var.create_admin_user ? 1 : 0
  user               = var.app_admin_username
  host               = "%"
  plaintext_password = var.app_admin_password
}

resource "mysql_user" "fincore_admin_proxy" {
  count              = var.create_admin_user ? 1 : 0
  user               = var.app_admin_username
  host               = "cloudsqlproxy~%"
  plaintext_password = var.app_admin_password
}

resource "mysql_grant" "fincore_admin_privileges" {
  count      = var.create_admin_user ? 1 : 0
  user       = mysql_user.fincore_admin[0].user
  host       = mysql_user.fincore_admin[0].host
  database   = var.database_name
  privileges = var.admin_privileges

  depends_on = [mysql_user.fincore_admin]
}

resource "mysql_grant" "fincore_admin_proxy_privileges" {
  count      = var.create_admin_user ? 1 : 0
  user       = mysql_user.fincore_admin_proxy[0].user
  host       = mysql_user.fincore_admin_proxy[0].host
  database   = var.database_name
  privileges = var.admin_privileges

  depends_on = [mysql_user.fincore_admin_proxy]
}

# Create read-only user for monitoring/reporting (optional)
resource "mysql_user" "fincore_readonly" {
  count              = var.create_readonly_user ? 1 : 0
  user               = var.readonly_username
  host               = "%"
  plaintext_password = var.readonly_password
}

resource "mysql_user" "fincore_readonly_proxy" {
  count              = var.create_readonly_user ? 1 : 0
  user               = var.readonly_username
  host               = "cloudsqlproxy~%"
  plaintext_password = var.readonly_password
}

resource "mysql_grant" "fincore_readonly_privileges" {
  count      = var.create_readonly_user ? 1 : 0
  user       = mysql_user.fincore_readonly[0].user
  host       = mysql_user.fincore_readonly[0].host
  database   = var.database_name
  privileges = ["SELECT"]

  depends_on = [mysql_user.fincore_readonly]
}

resource "mysql_grant" "fincore_readonly_proxy_privileges" {
  count      = var.create_readonly_user ? 1 : 0
  user       = mysql_user.fincore_readonly_proxy[0].user
  host       = mysql_user.fincore_readonly_proxy[0].host
  database   = var.database_name
  privileges = ["SELECT"]

  depends_on = [mysql_user.fincore_readonly_proxy]
}