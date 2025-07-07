resource "hcloud_firewall" "authentik" {
  name = "authentik-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "authentik-server" {
  name        = "authentik"
  image       = "ubuntu-24.04"
  server_type = "cx22"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys     = [var.ssh_key_id]
  firewall_ids = [hcloud_firewall.authentik.id]
}

resource "random_password" "pg_pass" {
  length  = 36
  special = false
  lower   = true
  upper   = true
  numeric = true
  keepers = {
    rotated_at = "2025-06-28"
  }
}


resource "cloudflare_dns_record" "authentik_record" {
  zone_id = var.cloudflare_zone_id
  name = "@"
  type = "A"
  comment = "Authentik dns record"
  content = hcloud_server.authentik-server.ipv4_address
  proxied = true
  ttl = 1
}

resource "random_password" "ak_secret" {
  length  = 60
  special = false
  keepers = {
    rotated_at = "2025-06-28"
  }
}

resource "random_password" "authentik_bootstrap_token" {
  length  = 36
  special = false
  lower   = true
  upper   = true
  numeric = true
}

resource "ansible_playbook" "authentik-cfg" {
  name       = hcloud_server.authentik-server.ipv4_address
  playbook   = "../../ansible/playbooks/authentik.yml"
  replayable = true

  extra_vars = {
    pg_pass     = random_password.pg_pass.result
    ak_secret   = random_password.ak_secret.result
    domain_name = var.domain_name
    authentik_bootstrap_token = random_password.authentik_bootstrap_token.result
    authentik_bootstrap_email = var.authentik_bootstrap_email
    authentik_bootstrap_password = var.authentik_bootstrap_password
  }

  depends_on = [hcloud_server.authentik-server]
}

