# ── k3s cluster token ───────────────────────────────────
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

# ── Private network (optional) ──────────────────────────
resource "scaleway_vpc_private_network" "cluster" {
  count  = var.create_network ? 1 : 0
  region = var.region
  name   = "${var.cluster_name}-network"

  ipv4_subnet {
    subnet = var.private_network_cidr
  }
}

# ── Security group (firewall) ────────────────────────────
resource "scaleway_instance_security_group" "cluster" {
  name                    = "${var.cluster_name}-sg"
  zone                    = var.zone
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  # SSH
  dynamic "inbound_rule" {
    for_each = var.ssh_allowed_cidrs
    content {
      action   = "accept"
      protocol = "TCP"
      port     = 22
      ip_range = inbound_rule.value
    }
  }

  # k3s API
  dynamic "inbound_rule" {
    for_each = var.k3s_api_allowed_cidrs
    content {
      action   = "accept"
      protocol = "TCP"
      port     = 6443
      ip_range = inbound_rule.value
    }
  }

  # NodePort services
  dynamic "inbound_rule" {
    for_each = var.nodeport_allowed_cidrs
    content {
      action     = "accept"
      protocol   = "TCP"
      port_range = "30000-32767"
      ip_range   = inbound_rule.value
    }
  }

  # Kubelet API, WireGuard overlay, and general inter-node traffic.
  # Scaleway security groups have no "same security group" source like
  # Exoscale's user_security_group_id, so inter-node traffic is scoped to
  # the private network CIDR when enabled, otherwise it is left to the
  # public-IP rules above (no blanket open inter-node rule).
  dynamic "inbound_rule" {
    for_each = var.create_network ? [var.private_network_cidr] : []
    content {
      action   = "accept"
      protocol = "TCP"
      port     = 10250
      ip_range = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = var.create_network ? [var.private_network_cidr] : []
    content {
      action     = "accept"
      protocol   = "UDP"
      port_range = "51820-51821"
      ip_range   = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = var.create_network ? [var.private_network_cidr] : []
    content {
      action   = "accept"
      protocol = "ANY"
      ip_range = inbound_rule.value
    }
  }

  # User-defined extra rules
  dynamic "inbound_rule" {
    for_each = var.extra_security_group_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }
}
