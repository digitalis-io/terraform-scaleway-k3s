# ── Cluster identity ─────────────────────────────────────
variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "digitalis-k3s"
}

# ── Server (control-plane) ─────────────────────────────────
variable "server_type" {
  description = "Scaleway instance commercial type for the control-plane node (e.g. DEV1-M, PLAY2-MICRO)"
  type        = string
  default     = "BASIC3-X4C-8G"
}

# ── Agent (worker) pool ──────────────────────────────────
variable "agent_count" {
  description = "Number of k3s agent (worker) nodes"
  type        = number
  default     = 2
}

variable "agent_type" {
  description = "Scaleway instance commercial type for agent/worker nodes"
  type        = string
  default     = "DEV1-M"
}

# ── Zone, region & image ─────────────────────────────────
variable "zone" {
  description = "Scaleway zone (e.g. fr-par-1, fr-par-2, nl-ams-1, pl-waw-1)"
  type        = string
  default     = "fr-par-1"
}

variable "region" {
  description = "Scaleway region matching the zone (e.g. fr-par, nl-ams, pl-waw). Private networks are regional."
  type        = string
  default     = "fr-par"
}

variable "image" {
  description = "Marketplace image label for all nodes"
  type        = string
  default     = "ubuntu_noble"
}

variable "disk_size" {
  description = "Root volume size in GB for all nodes"
  type        = number
  default     = 20
}

# ── Networking ───────────────────────────────────────────
variable "create_network" {
  description = "Attach nodes to a Scaleway VPC private network. Note: node-to-node k3s join still uses public IPs — Scaleway private networks are DHCP-assigned and have no built-in static addressing without IPAM."
  type        = bool
  default     = false
}

variable "private_network_cidr" {
  description = "IPv4 subnet CIDR for the Scaleway VPC private network"
  type        = string
  default     = "10.13.1.0/24"
}

# ── Security group (firewall) ─────────────────────────────
variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH into nodes"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "k3s_api_allowed_cidrs" {
  description = "CIDRs allowed to reach the k3s API (port 6443)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nodeport_allowed_cidrs" {
  description = "CIDRs allowed to reach NodePort services (30000-32767). Set to empty list to disable."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_security_group_rules" {
  description = "Additional inbound security group rules to apply to all nodes"
  type = list(object({
    action     = optional(string, "accept")
    protocol   = optional(string, "TCP")
    port       = optional(number)
    port_range = optional(string)
    ip_range   = string
  }))
  default = []
}

# ── k3s options ──────────────────────────────────────────
variable "k3s_version" {
  description = "k3s version to install (e.g. v1.31.4+k3s1). Empty string installs the stable channel."
  type        = string
  default     = ""
}

variable "k3s_server_extra_args" {
  description = "Extra arguments passed to the k3s server install"
  type        = string
  default     = ""
}

variable "k3s_agent_extra_args" {
  description = "Extra arguments passed to the k3s agent install"
  type        = string
  default     = ""
}

variable "flannel_backend" {
  description = "Flannel backend (wireguard-native, vxlan, host-gw, etc.)"
  type        = string
  default     = "wireguard-native"
}

# ── Optional tool installation ───────────────────────────
variable "install_helm" {
  description = "Install Helm 3 on the server node"
  type        = bool
  default     = true
}

variable "install_k9s" {
  description = "Install k9s on all nodes"
  type        = bool
  default     = true
}

variable "install_stern" {
  description = "Install Stern on all nodes"
  type        = bool
  default     = true
}

# ── Extra tags ────────────────────────────────────────────
variable "extra_labels" {
  description = "Additional key:value tags to apply to all nodes (Scaleway instances only support flat string tags, not maps)"
  type        = map(string)
  default     = {}
}
