terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.18.0"
    }
  }
}

# Credentials come only from the existing AWS credential chain (for example SSO).
# Never add access_key or secret_key arguments, and never commit local state.
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.approved_account_id]
  default_tags {
    tags = {
      Application = "LabLedger"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
