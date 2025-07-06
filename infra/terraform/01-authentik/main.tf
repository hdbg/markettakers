provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "local_file" "local_ssh_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}

resource "hcloud_ssh_key" "prod" {
  name       = "prod-key"
  public_key = data.local_file.local_ssh_key.content
}

module "authentik-deployment" {
  source = "./modules/authentik-deploy"

  providers = {
    hcloud     = hcloud
    cloudflare = cloudflare
  }

  ssh_key_id = hcloud_ssh_key.prod.id

  domain_name        = var.domain_name
  cloudflare_zone_id = var.cloudflare_zone_id

  authentik_bootstrap_password = var.authentik_bootstrap_password
  authentik_bootstrap_email    = var.authentik_bootstrap_email
}

provider "authentik" {
  url   = "https://${var.domain_name}"
  token = module.authentik-deployment.authentik_token
}

module "authentik-config" {
  source = "./modules/authentik-config"

  providers = {
    authentik = authentik
  }

  depends_on = [module.authentik-deployment]
}