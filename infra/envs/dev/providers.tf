terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.9" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.20" }
  }
  backend "s3" {
    bucket         = "<STATE_BUCKET_NAME>"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-3"
}
