terraform {
  backend "gcs" {
    bucket = "fincore-prod-terraform-state"
    prefix = "prod"
  }
}