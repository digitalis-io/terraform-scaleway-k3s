locals {
  server_tags = concat(
    ["cluster:${var.cluster_name}", "role:server"],
    [for k, v in var.extra_labels : "${k}:${v}"]
  )
}

resource "scaleway_instance_server" "server" {
  zone              = var.zone
  name              = "${var.cluster_name}-server"
  type              = var.server_type
  image             = var.image
  security_group_id = scaleway_instance_security_group.cluster.id
  tags              = local.server_tags
  enable_dynamic_ip = true

  root_volume {
    size_in_gb = var.disk_size
  }

  user_data = {
    cloud-init = templatefile("${path.module}/templates/server.yaml.tftpl", {
      k3s_token             = random_password.k3s_token.result
      k3s_version           = var.k3s_version
      k3s_server_extra_args = var.k3s_server_extra_args
      flannel_backend       = var.flannel_backend
      install_helm          = var.install_helm
      install_k9s           = var.install_k9s
      install_stern         = var.install_stern
    })
  }

  dynamic "private_network" {
    for_each = var.create_network ? [scaleway_vpc_private_network.cluster[0].id] : []
    content {
      pn_id = private_network.value
    }
  }
}
