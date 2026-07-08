# Advanced Example

This example demonstrates a k3s cluster with a private network, a larger worker pool, custom sizing, and restricted access.

## Features

- **Private Networking**: Scaleway VPC private network for inter-node traffic
- **Worker Pool**: 5 agent nodes for workloads
- **Custom Sizing**: Non-default server/agent instance types
- **Security**: Restricted SSH and API access to specific CIDRs
- **WireGuard**: Native WireGuard backend for Flannel CNI
- **Selective Tooling**: Only install helm, skip k9s and stern

## Usage

```hcl
module "k3s" {
  source  = "digitalis-io/k3s/scaleway"
  version = "~> 1.0"

  cluster_name = "production-k3s"
  zone         = "fr-par-2"
  region       = "fr-par"

  server_type = "BASIC3-X4C-8G"

  agent_count = 5
  agent_type  = "DEV1-M"

  create_network       = true
  private_network_cidr = "10.50.1.0/24"

  ssh_allowed_cidrs     = ["203.0.113.0/24"]
  k3s_api_allowed_cidrs = ["203.0.113.0/24"]

  flannel_backend = "wireguard-native"

  install_helm  = true
  install_k9s   = false
  install_stern = false

  extra_labels = {
    environment = "production"
    team        = "platform"
  }
}
```

## Prerequisites

1. A Scaleway account with an API access key, secret key, and project ID
2. At least one SSH key registered against your Scaleway project
3. Knowledge of your allowed IP ranges for SSH and API access

## Running this example

```bash
# Set your Scaleway credentials
export SCW_ACCESS_KEY="your-access-key"
export SCW_SECRET_KEY="your-secret-key"
export SCW_DEFAULT_PROJECT_ID="your-project-id"

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply
terraform apply
```

## Outputs

| Name | Description |
|------|-------------|
| `server_ip` | Public IP address of the k3s server node |
| `agent_ips` | Public IP addresses of all k3s agent nodes |
| `kubeconfig_cmd` | Command to fetch the kubeconfig file |
