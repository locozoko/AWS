variable "name-prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource-tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "Cloud Connector VPC"
}

variable iam-role-policy-smrw {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "SecretsManagerReadWrite"
}

variable iam-role-policy-ssmcore {
  description = "Cloud Connector EC2 Instance IAM Role"
  default     = "AmazonSSMManagedInstanceCore"
}

variable cc-count {
  description = "No of Cloud Connector EC2 Instances"
  default     = 1
}

variable mgmt-subnet-id {
  description = "Cloud Connector EC2 Instance management subnet id"
}

variable service-subnet-id {
  description = "Cloud Connector EC2 Instance service subnet id"
}

variable instance-key {
  description = "Cloud Connector Instance Key"
}

variable user-data {
  description = "Cloud Init data"
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
