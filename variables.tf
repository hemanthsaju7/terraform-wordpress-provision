variable "region" {
  default = "ap-south-1"
}

variable "cidr_block" {
  default = "172.25.0.0/16"
}

variable "project_name" {
  default = "zomato"
}

variable "project_env" {
  default = "prod"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_ami" {
  default = "ami-id"
}

variable "hosted_zone" {
  default = "your-zone-id"   
}
