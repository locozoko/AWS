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

variable "cc-vm1-id" {
  description = "Cloud Connector 1 instance id"
}

variable "cc-vm2-id" {
  description = "Cloud Connector 2 instance id"
}

variable "cc-vm1-snid" {
  description = "Cloud Connector 1's service subnet id"
}

variable "cc-vm2-snid" {
  description = "Cloud Connector 2's service subnet id"
}

variable "cc-vm1-rte-list" {
  type = list(string)
  description = "List of route tables using Cloud Connector 1 instance id"
}

variable "cc-vm2-rte-list" {
  type = list(string)
  description = "List of route tables using Cloud Connector 2 instance id"
}

variable "http-probe-port" {
  description = "HTTP port to send the health probes on Cloud Connector cloud"
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

variable "route-updater-filename" {
  description = "Route updater lambda deployment package filename"
  #default     = "checker_lambda_function.zip"
  default     = "rte_updater_lambda.py.zip"
}

variable "route-updater-handler" {
  description = "Route updater lambda handler"
  default     = "rte_updater_lambda.lambda_handler"
}

variable "route-updater-runtime" {
  description = "Route updater lambda runtime"
  default     = "python3.8"
}
