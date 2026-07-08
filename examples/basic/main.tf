terraform {
  required_version = ">= 1.5.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.45.0"
    }
  }
}

variable "scw_access_key" {
  description = "Scaleway access key. Can also be set via the SCW_ACCESS_KEY environment variable."
  type        = string
  default     = null
}

variable "scw_secret_key" {
  description = "Scaleway secret key. Can also be set via the SCW_SECRET_KEY environment variable."
  type        = string
  default     = null
  sensitive   = true
}

variable "scw_project_id" {
  description = "Scaleway project ID. Can also be set via the SCW_DEFAULT_PROJECT_ID environment variable."
  type        = string
  default     = null
}

provider "scaleway" {
  access_key = var.scw_access_key
  secret_key = var.scw_secret_key
  project_id = var.scw_project_id
}

module "k3s" {
  source = "../../"
}

output "server_ip" {
  value = module.k3s.server_public_ip
}

output "kubeconfig_cmd" {
  value = module.k3s.kubeconfig_command
}
