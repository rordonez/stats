terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.13.1"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region

  profile = var.environment
}
