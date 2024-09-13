terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.66.0"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "~> 2.3.5"
    }
    external = {
      source = "hashicorp/external"
      version = "~> 2.3.4"
    }
    http = {
      source = "hashicorp/http"
      version = "~> 3.4.5"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.3"
    }
  }
}

provider "aws" {
  region = var.aws_region

  access_key = jsondecode(file(var.aws_cred_file)).aws_access_key_id
  secret_key = jsondecode(file(var.aws_cred_file)).aws_secret_access_key
}

data "aws_availability_zones" "available" {
  state = "available"
}
