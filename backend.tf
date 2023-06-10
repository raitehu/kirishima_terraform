terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket  = "cloudgate-terraform-backend"
    region  = "ap-northeast-1"
    key     = "terraform.tfstate"
    encrypt = true
  }
}
