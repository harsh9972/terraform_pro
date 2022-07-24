terraform {

  backend "s3" {
    bucket = "tf-proj-s3"
    key    = "terraform.tfstate"
    region = "ca-central-1"
  }

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.8.0"
    }
  }
}



#Configure the AWS Server
provider "aws" {
    region = "ca-central-1"
}