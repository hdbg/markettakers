data "authentik_property_mapping_provider_scope" "tailscale" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_provider_oauth2" "tailscale" {
  name      = "tailscale"
  client_id = "tailscale"
  invalidation_flow = data.authentik_flow.default_invalidation_flow.id
  authorization_flow = data.authentik_flow.default_explicit_flow.id
  client_type = "confidential"
  property_mappings = data.authentik_property_mapping_provider_scope.tailscale.ids
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://login.tailscale.com/a/oauth_response",
    }
  ]

  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "tailscale" {
  name              = "Tailscale"
  slug              = "tailscale"
  protocol_provider = authentik_provider_oauth2.tailscale.id
}