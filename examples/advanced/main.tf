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

  cluster_name = "production-k3s"
  zone         = "fr-par-2"
  region       = "fr-par"

  server_type = "BASIC3-X4C-8G"

  # Worker pool
  agent_count = 5
  agent_type  = "DEV1-M"

  # Private network for inter-node traffic
  create_network       = true
  private_network_cidr = "10.50.1.0/24"

  # Restrict access to your office/VPN
  ssh_allowed_cidrs     = ["203.0.113.0/24"]
  k3s_api_allowed_cidrs = ["203.0.113.0/24"]

  flannel_backend = "wireguard-native"

  # Only install helm, skip k9s and stern
  install_helm  = true
  install_k9s   = false
  install_stern = false

  extra_labels = {
    environment = "production"
    team        = "platform"
  }
}

output "server_ip" {
  value = module.k3s.server_public_ip
}

output "agent_ips" {
  value = module.k3s.agent_public_ips
}

output "kubeconfig_cmd" {
  value = module.k3s.kubeconfig_command
}
