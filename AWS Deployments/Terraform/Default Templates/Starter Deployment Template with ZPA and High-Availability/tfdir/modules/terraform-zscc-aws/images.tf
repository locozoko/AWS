variable "images" {
  description = "Cloud Connector AMI id"
  type        = map
  default = {
    us-west-1    = "ami-03b285a4bb9321b5f"
    us-east-1    = "ami-0fc5e06f5105bf2e9"
    us-east-2    = "ami-0b961500448c0bbb2"
    eu-central-1 = "ami-0ce0ee102874eef66"
    eu-west-1    = "ami-05cc961261c10bf12"
    eu-west-2    = "ami-0a2ef822a8bc2b83e"
    eu-west-3    = "ami-0da60de20238b69d1"
    us-west-2    = "ami-0050e9f2fcb278da0"
  }
}
