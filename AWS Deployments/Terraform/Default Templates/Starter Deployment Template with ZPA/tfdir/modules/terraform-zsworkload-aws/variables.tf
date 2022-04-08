variable "name-prefix" {
  description = "A prefix to associate to all the module resources"
  default     = "zscaler-cc"
}

variable "resource-tag" {
  description = "A tag to associate to all the module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Main VPC"
}

variable "subnet" {
  description = "The private subnet where the server has to be attached"
}

variable "instance-type" {
  description = "The server instance type"
  default     = "t3.micro"
}

variable instance-key {
  description = "SSH Key for instances"
}