# aws variables

variable "aws-region" {
  description = "The AWS region."
  default     = "us-west-2"
}

variable "name-prefix" {
  description = "The name prefix for all your resources"
  default     = "zsdemo"
  type        = string
}

variable "vpc-cidr" {
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "subnet-count" {
  description = "Default number of worker subnets to create"
  default     = 1
}

variable "keyname" {
  default = "zs"
  type    = string
}

variable "public-key" {
  default = ""
  type    = string
}

variable "instance-per-subnet" {
  default = 1
}

variable "byo_eip_address" {
  default     = false
  type        = bool
  description = "Bring your own Elastic IP address for the NAT GW"
}

variable "nat_eip1_id" {
  default     = ""
  type        = string
  description = "User provided Elastic IP address ID for the NAT GW"
}

variable "http-probe-port" {
  description = "port for Cloud Connector cloud init to enable listener port for HTTP probe from LB"
  default = 0
  validation {
          condition     = (
            var.http-probe-port == 0 ||
            var.http-probe-port == 80 ||
          ( var.http-probe-port >= 1024 && var.http-probe-port <= 65535 )
        )
          error_message = "Input http-probe-port must be set to a single value of 80 or any number between 1024-65535."
      }
}

variable cc_vm_prov_url {
  description = "Zscaler Cloud Connector Provisioning URL"
  type        = string
}

variable secret_name {
  description = "AWS Secrets Manager Secret Name for Cloud Connector provisioning"
  type        = string
}

variable ccvm-instance-type {
  description = "Cloud Connector Instance Type"
  default     = "t3.medium"
  validation {
          condition     = ( 
            var.ccvm-instance-type == "t3.medium" ||
            var.ccvm-instance-type == "t2.medium" ||
            var.ccvm-instance-type == "m5.large"  ||
            var.ccvm-instance-type == "c5.large"  ||
            var.ccvm-instance-type == "c5a.large" 
          )
          error_message = "Input ccvm-instance-type must be set to an approved vm instance type."
      }
}
