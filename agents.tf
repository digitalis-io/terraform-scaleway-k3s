locals {
  # When the private network is enabled, agents join via the server's
  # private IP. Otherwise, they join via the server's public IP.
  k3s_join_ip = var.create_network ? scaleway_instance_server.server.private_ips[0].address : try(scaleway_instance_server.server.public_ips[0].address, "")

  agent_tags = concat(
    ["cluster:${var.cluster_name}", "role:agent"],
    [for k, v in var.extra_labels : "${k}:${v}"]
  )
}

resource "scaleway_instance_server" "agent" {
  count             = var.agent_count
  zone              = var.zone
  name              = "${var.cluster_name}-agent-${count.index + 1}"
  type              = var.agent_type
  image             = var.image
  security_group_id = scaleway_instance_security_group.cluster.id
  tags              = local.agent_tags
  enable_dynamic_ip = true

  root_volume {
    size_in_gb = var.disk_size
  }

  user_data = {
    cloud-init = templatefile("${path.module}/templates/agent.yaml.tftpl", {
      k3s_token            = random_password.k3s_token.result
      k3s_version          = var.k3s_version
      k3s_join_url         = "https://${local.k3s_join_ip}:6443"
      k3s_agent_extra_args = var.k3s_agent_extra_args
      flannel_backend      = var.flannel_backend
      install_k9s          = var.install_k9s
      install_stern        = var.install_stern
    })
  }

  dynamic "private_network" {
    for_each = var.create_network ? [scaleway_vpc_private_network.cluster[0].id] : []
    content {
      pn_id = private_network.value
    }
  }

  # Agents must wait for the server to be ready and joinable
  depends_on = [scaleway_instance_server.server]
}
