# Security Module - Service Accounts and IAM

resource "google_service_account" "cloud_run" {
  account_id   = "${var.name_prefix}-${var.environment}-cloudrun"
  display_name = "Cloud Run Service Account"
  description  = "Service account for Cloud Run services"
}

resource "google_service_account" "secrets" {
  account_id   = "${var.name_prefix}-${var.environment}-secrets"
  display_name = "Secrets Manager Service Account"
  description  = "Service account for accessing secrets"
}

# Grant Cloud SQL client role to Cloud Run service account
resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

output "cloud_run_service_account" {
  value = google_service_account.cloud_run.email
}

output "secrets_service_account" {
  value = google_service_account.secrets.email
}