# terraform-scaleway-k3s

A Terraform module to deploy a [k3s](https://k3s.io/) Kubernetes cluster on [Scaleway](https://www.scaleway.com/), built by [Digitalis.io](https://digitalis.io).

## Features

- Single control-plane server plus a configurable agent (worker) pool
- Module-managed security group with configurable CIDR allowlists for SSH, k3s API, and NodePort services
- Optional Scaleway VPC private network for inter-node traffic
- WireGuard-native Flannel backend by default
- Optional tool installation: Helm, k9s, Stern
- Works with any Scaleway commercial instance type and marketplace image

## Quick Start

Set your Scaleway credentials:

```bash
export SCW_ACCESS_KEY="your-access-key"
export SCW_SECRET_KEY="your-secret-key"
export SCW_DEFAULT_PROJECT_ID="your-project-id"
```

Then create a minimal configuration:

```hcl
provider "scaleway" {}

module "k3s" {
  source = "github.com/digitalis-io/terraform-scaleway-k3s"
}

output "server_ip" {
  value = module.k3s.server_public_ip
}

output "kubeconfig_cmd" {
  value = module.k3s.kubeconfig_command
}
```

This creates a 3-node cluster (1 server + 2 agents) in `fr-par-1`.

> **Note:** Scaleway automatically injects every SSH key registered against your project into new instances — there is no `ssh_key_name` variable to set.

## Accessing the Cluster

After `terraform apply`, fetch the kubeconfig:

```bash
# Use the output command directly
$(terraform output -raw kubeconfig_cmd) > ~/.kube/config

# Or manually
ssh root@<server_ip> cat /etc/rancher/k3s/k3s.yaml | \
  sed "s/127.0.0.1/<server_ip>/g" > ~/.kube/config
```

## Restricting Access

By default, SSH, the k3s API, and NodePort services are open to all IPs. Restrict them to your network:

```hcl
module "k3s" {
  source = "github.com/digitalis-io/terraform-scaleway-k3s"

  ssh_allowed_cidrs      = ["203.0.113.0/24"]
  k3s_api_allowed_cidrs  = ["203.0.113.0/24"]

  # Disable NodePort access from the internet
  nodeport_allowed_cidrs = []
}
```

## Custom Security Group Rules

Add extra rules using the `extra_security_group_rules` variable:

```hcl
module "k3s" {
  source = "github.com/digitalis-io/terraform-scaleway-k3s"

  extra_security_group_rules = [
    {
      protocol = "TCP"
      port     = 443
      ip_range = "0.0.0.0/0"
    }
  ]
}
```

## Private Networking

By default nodes communicate over public IPs only. Enable a Scaleway VPC private network for inter-node traffic:

```hcl
module "k3s" {
  source               = "github.com/digitalis-io/terraform-scaleway-k3s"
  create_network       = true
  private_network_cidr = "10.13.1.0/24"
}
```

> Scaleway private networks are DHCP-assigned with no built-in static addressing without IPAM, so agents join the cluster via the server's public IP unless `create_network` is enabled, in which case the server's private IP is used instead.

## Sizing the Cluster

```hcl
module "k3s" {
  source = "github.com/digitalis-io/terraform-scaleway-k3s"

  server_type = "BASIC3-X4C-8G"
  agent_type  = "DEV1-M"
  agent_count = 5

  zone   = "fr-par-2"
  region = "fr-par"
}
```

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| scaleway provider | >= 2.45.0 |
| random provider | >= 3.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Name prefix for all resources | `string` | `"digitalis-k3s"` | no |
| `server_type` | Scaleway instance commercial type for the control-plane node | `string` | `"BASIC3-X4C-8G"` | no |
| `agent_count` | Number of k3s agent (worker) nodes | `number` | `2` | no |
| `agent_type` | Scaleway instance commercial type for agent/worker nodes | `string` | `"DEV1-M"` | no |
| `zone` | Scaleway zone (e.g. `fr-par-1`, `fr-par-2`, `nl-ams-1`, `pl-waw-1`) | `string` | `"fr-par-1"` | no |
| `region` | Scaleway region matching the zone. Private networks are regional | `string` | `"fr-par"` | no |
| `image` | Marketplace image label for all nodes | `string` | `"ubuntu_noble"` | no |
| `disk_size` | Root volume size in GB for all nodes | `number` | `20` | no |
| `create_network` | Attach nodes to a Scaleway VPC private network | `bool` | `false` | no |
| `private_network_cidr` | IPv4 subnet CIDR for the Scaleway VPC private network | `string` | `"10.13.1.0/24"` | no |
| `ssh_allowed_cidrs` | CIDRs allowed to SSH into nodes | `list(string)` | `["0.0.0.0/0"]` | no |
| `k3s_api_allowed_cidrs` | CIDRs allowed to reach the k3s API (port 6443) | `list(string)` | `["0.0.0.0/0"]` | no |
| `nodeport_allowed_cidrs` | CIDRs allowed to reach NodePort services (30000-32767) | `list(string)` | `["0.0.0.0/0"]` | no |
| `extra_security_group_rules` | Additional inbound security group rules to apply to all nodes | `list(object)` | `[]` | no |
| `k3s_version` | k3s version (e.g. `v1.31.4+k3s1`). Empty = stable channel | `string` | `""` | no |
| `k3s_server_extra_args` | Extra arguments for k3s server install | `string` | `""` | no |
| `k3s_agent_extra_args` | Extra arguments for k3s agent install | `string` | `""` | no |
| `flannel_backend` | Flannel backend | `string` | `"wireguard-native"` | no |
| `install_helm` | Install Helm 3 on the server node | `bool` | `true` | no |
| `install_k9s` | Install k9s on all nodes | `bool` | `true` | no |
| `install_stern` | Install Stern on all nodes | `bool` | `true` | no |
| `extra_labels` | Additional key:value tags to apply to all nodes (Scaleway instances only support flat string tags, not maps) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `server_public_ip` | Public IPv4 address of the server node |
| `server_private_ip` | Private IP of the server node. Null when `create_network` is false |
| `agent_public_ips` | Map of agent node names to public IPv4 addresses |
| `agent_private_ips` | Map of agent node names to private IPs |
| `k3s_token` | k3s cluster token (sensitive) |
| `private_network_id` | ID of the Scaleway VPC private network. Null when `create_network` is false |
| `security_group_id` | ID of the cluster security group |
| `kubeconfig_command` | Command to fetch kubeconfig from the server |

## Architecture

The module creates the following resources:

- **Security group** with rules for SSH, k3s API, NodePort services, and (when `create_network` is enabled) inter-node traffic scoped to the private network CIDR
- **Private network** (optional) for inter-node communication
- **Server node** running k3s in server mode (control plane + etcd)
- **Agent nodes** running k3s in agent mode (workers only)

All nodes are provisioned via cloud-init with automatic k3s installation and cluster joining.

## License

See [LICENSE](LICENSE) for details.

## Support

Maintained by [Digitalis.io](https://digitalis.io). For support, visit [digitalis.io/contact](https://digitalis.io/contact).
