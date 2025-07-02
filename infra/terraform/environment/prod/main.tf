data "local_file" "local_ssh_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}

resource "hcloud_ssh_key" "me" {
  name       = "laptop-key"
  public_key = data.local_file.local_ssh_key.content
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "prod" {
  name       = "global-key"
  public_key = data.local_file.local_ssh_key.content
}

module "authentik-deployment" {
  source  = "../../modules/authentik-deploy"

  ssh_key_id = hcloud_ssh_key.prod.id

  domain_name = var.domain_name
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id = var.cloudflare_zone_id
  hcloud_token = var.hcloud_token

  authentik_bootstrap_password = var.authentik_bootstrap_password
  authentik_bootstrap_email = var.authentik_bootstrap_email
 
}
