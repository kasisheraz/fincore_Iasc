variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "terraform_state_bucket" {
  description = "Terraform state bucket"
  type        = string
}

variable "artifacts_bucket" {
  description = "Artifacts bucket"
  type        = string
}

variable "uploads_bucket" {
  description = "Uploads bucket"
  type        = string
}