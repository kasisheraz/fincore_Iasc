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

variable "vpc_cidr_range" {
  description = "CIDR range for VPC"
  type        = string
}

variable "subnet_cidr_range" {
  description = "CIDR range for subnet"
  type        = string
}