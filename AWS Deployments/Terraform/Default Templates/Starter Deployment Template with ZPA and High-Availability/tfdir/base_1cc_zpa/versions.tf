terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.42"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.2"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
