variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
}

variable "public_subnet_a_cidr" {
  type        = string
  description = "public subnet a cidr"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "public subnet b cidr"
}

variable "public_subnet_c_cidr" {
  type        = string
  description = "public subnet c cidr"
}

variable "private_subnet_a_cidr" {
  type        = string
  description = "private subnet a cidr"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "private subnet b cidr"
}

variable "private_subnet_c_cidr" {
  type        = string
  description = "private subnet c cidr"
}
