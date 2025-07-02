module "authentik-deployment" {
  source  = "../../modules/authentik-deploy"

  domain_name = var.domain_name
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id = var.cloudflare_zone_id
  hcloud_token = var.hcloud_token

  authentik_bootstrap_password = var.authentik_bootstrap_password
  authentik_bootstrap_email = var.authentik_bootstrap_email
 
}
