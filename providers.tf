terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "af-south-1"
  default_tags {
    tags = {
      APP   = "capitec-terraform-training"
      OWNER = "Geeks4Learning"
    }
  }
}