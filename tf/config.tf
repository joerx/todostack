terraform {
  required_version = ">= 0.9"
}

provider "aws" {
  region = "${var.aws_region}"
}
