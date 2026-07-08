# Basic Example

This example demonstrates the minimal configuration needed to deploy a k3s cluster (1 server + 2 agents) on Scaleway.

## Usage

```hcl
module "k3s" {
  source  = "digitalis-io/k3s/scaleway"
  version = "~> 1.0"
}
```

## Prerequisites

1. A Scaleway account with an API access key, secret key, and project ID
2. At least one SSH key registered against your Scaleway project (Scaleway injects all project SSH keys automatically)

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
| `server_ip` | Public IP address of the k3s server |
| `kubeconfig_cmd` | Command to fetch the kubeconfig file |
