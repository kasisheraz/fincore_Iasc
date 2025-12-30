# Minimal Configuration Variables
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