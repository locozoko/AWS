variable "name-prefix" {
  description = "A prefix to associate to all the Cloud Connector module resources"
  default     = "zscaler-cc"
}

variable "resource-tag" {
  description = "A tag to associate to all the Cloud Connector module resources"
  default     = "cloud-connector"
}

variable "vpc" {
  description = "VPC id for the Route53 Endpoint"
}

variable subnet-1 {
  description = "Subnet 1 for the Route53 Endpoint"
}

variable subnet-2 {
  description = "Subnet 2 for the Route53 Endpoint"
}

variable domain-name {
  description = "The domain name that requires forwarding to a custom DNS server"
}

variable target-address {
  description = "DNS queries will be forwarded to this IPv4 addresse"
  default     = "8.8.8.8"
}
