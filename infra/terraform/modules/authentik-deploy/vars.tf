variable "domain_name" {}

variable "cloudflare_api_token" {
  sensitive = true
}
variable "cloudflare_zone_id" {}

variable "hcloud_token" {
  sensitive = true
}

variable "authentik_bootstrap_password" {
  sensitive = true
}
variable "authentik_bootstrap_email" {}

variable "ssh_key_id" {}

