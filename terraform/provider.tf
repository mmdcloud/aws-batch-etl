terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
  # backend "s3" {
  #   bucket         = "carshubtfstate"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "carshub-terraform-locks-prod"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

provider "vault" {}