output "server_public_ip" {
  description = "Public IPv4 address of the server node"
  value       = try(scaleway_instance_server.server.public_ips[0].address, null)
}

output "server_private_ip" {
  description = "Private IP of the server node. Null when create_network is false."
  value       = var.create_network ? scaleway_instance_server.server.private_ips[0].address : null
}

output "agent_public_ips" {
  description = "Map of agent node names to public IPv4 addresses"
  value       = { for s in scaleway_instance_server.agent : s.name => try(s.public_ips[0].address, null) }
}

output "agent_private_ips" {
  description = "Map of agent node names to private IPs"
  value       = var.create_network ? { for s in scaleway_instance_server.agent : s.name => s.private_ips[0].address } : {}
}

output "k3s_token" {
  description = "k3s cluster token"
  value       = random_password.k3s_token.result
  sensitive   = true
}

output "private_network_id" {
  description = "ID of the Scaleway VPC private network. Null when create_network is false."
  value       = var.create_network ? scaleway_vpc_private_network.cluster[0].id : null
}

output "security_group_id" {
  description = "ID of the cluster security group"
  value       = scaleway_instance_security_group.cluster.id
}

output "kubeconfig_command" {
  description = "Command to fetch kubeconfig from the server"
  value       = "ssh root@${try(scaleway_instance_server.server.public_ips[0].address, "")} cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${try(scaleway_instance_server.server.public_ips[0].address, "")}/g'"
}
