variable "domain_name" {}

variable "cloudflare_zone_id" {}

variable "authentik_bootstrap_password" {
  sensitive = true
}
variable "authentik_bootstrap_email" {}

variable "ssh_key_id" {}

