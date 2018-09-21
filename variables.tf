variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {}
variable "vpc_id" {}

variable "ami" {
  default = ""
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = ""
}

variable "subnet_id" {}
