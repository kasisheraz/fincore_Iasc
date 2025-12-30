terraform {
  required_version = ">= 1.6.0"

  backend "gcs" {
    # Backend configuration will be provided via -backend-config flag
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}