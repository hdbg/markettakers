output "tailscale_client_id" {
    value = authentik_provider_oauth2.tailscale.client_id
}

output "tailscale_client_secret" {
    value = authentik_provider_oauth2.tailscale.client_secret
    sensitive = true
}