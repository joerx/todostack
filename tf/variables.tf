variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_availability_zones" {
  default = [
    "ap-southeast-1a",
    "ap-southeast-1b"
  ]
}

variable "project_name" {
  default = "my-project"
}

variable "keypair_name" {
  type = "string"
}

# amazon linux ecs optimized ami
variable "aws_ami_ids" {
  type = "map"
  default = {
    "us-east-1" = "ami-9eb4b1e5"
    "us-east-2" = "ami-1c002379"
    "ap-southeast-1" = "ami-9d1f7efe"
  }
}
