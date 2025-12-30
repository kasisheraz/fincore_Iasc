terraform {
  backend "gcs" {
    bucket = "fincore-npe-terraform-state"
    prefix = "npe"
  }
}