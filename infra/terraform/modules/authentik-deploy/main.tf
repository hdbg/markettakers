provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "hcloud" {
  token = var.hcloud_token
}

data "local_file" "local_ssh_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}

resource "hcloud_ssh_key" "me" {
  name       = "laptop-key"
  public_key = data.local_file.local_ssh_key.content
}

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
  ssh_keys     = [hcloud_ssh_key.me.id]
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

resource "ansible_group" "authentik" {
  name = "authentik"
}

resource "ansible_host" "authentik-server" {
  name   = hcloud_server.authentik-server.ipv4_address
  groups = [ansible_group.authentik.name]

  variables = {
    ansible_user = "root"
  }

}

resource "ansible_playbook" "authentik-cfg" {
  name       = ansible_host.authentik-server.name
  playbook   = "../../../ansible/playbooks/authentik.yml"
  groups     = [ansible_group.authentik.name] # targets the group, not an IP
  replayable = true

  extra_vars = {
    pg_pass     = random_password.pg_pass.result
    ak_secret   = random_password.ak_secret.result
    domain_name = var.domain_name
    authentik_bootstrap_token = random_password.authentik_bootstrap_token.result
    authentik_bootstrap_email = var.authentik_bootstrap_email
    authentik_bootstrap_password = var.authentik_bootstrap_password
  }

  verbosity = 5
}

