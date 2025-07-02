output "authentik_token" {
  value     = random_password.authentik_bootstrap_token.result
  sensitive = true
}