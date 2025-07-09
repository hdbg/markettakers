resource "harvester_virtualmachine" "outline" {
  name      = "outline"
  namespace = "default"

  tags = {
    ssh-user = "fedora"
    service  = "outline"
  }

  cpu    = 2
  memory = "4Gi"

  efi         = true
  secure_boot = true

  network_interface {
    name = "nic-1"
    type = "bridge"
  }

  disk {
    name       = "disk"
    type       = "disk"
    size       = "20Gi"
    bus        = "virtio"
    boot_order = 1

    image = var.fedora_cloud_42_image

    auto_delete = true
  }

  cloudinit {
    user_data_secret_name = var.cloud_init_service_secret
  }
}

data "tailscale_device" "outline" {
  depends_on = [harvester_virtualmachine.outline]

  hostname = harvester_virtualmachine.outline.name
  wait_for = "360s"
}

resource "random_bytes" "outline_secret" {
  length = 32
}

resource "random_bytes" "outline_util_secret" {
  length = 32
}

data "authentik_property_mapping_provider_scope" "outline" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

data "authentik_flow" "default_implicit_flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_explicit_flow" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-invalidation-flow"
}


locals {
  public_url = data.tailscale_device.outline.name != null ? "https://${data.tailscale_device.outline.name}" : "http://localhost:3000"
}

resource "authentik_provider_oauth2" "outline" {
  depends_on = [harvester_virtualmachine.outline, data.tailscale_device.outline]

  name               = "Outline"
  client_id          = "outline"
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
  authorization_flow = data.authentik_flow.default_explicit_flow.id
  client_type        = "confidential"
  property_mappings  = data.authentik_property_mapping_provider_scope.outline.ids
  allowed_redirect_uris = [
    {
      matching_mode = "regex",
      url           = "${local.public_url}/.*",
    }
  ]

  sub_mode = "user_username"

  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "outline" {
  name              = "Outline"
  slug              = "outline"
  protocol_provider = authentik_provider_oauth2.outline.id
}

resource "ansible_playbook" "outline" {
  name       = data.tailscale_device.outline.addresses[0]
  playbook   = "../../ansible/playbooks/outline.yml"
  replayable = true

  extra_vars = {
    public_url   = local.public_url
    secret_key   = random_bytes.outline_secret.hex
    utils_secret = random_bytes.outline_util_secret.hex

    sso_client_id     = authentik_provider_oauth2.outline.client_id
    sso_client_secret = authentik_provider_oauth2.outline.client_secret
    sso_auth_uri      = "https://${var.authentik_domain}/application/o/authorize/"
    sso_token_uri     = "https://${var.authentik_domain}/application/o/token/"
    sso_userinfo_uri  = "https://${var.authentik_domain}/application/o/userinfo/"
    sso_logout_uri    = "https://${var.authentik_domain}/application/o/${authentik_provider_oauth2.outline.client_id}/end-session/"
  }

  force_handlers = true

  depends_on = [harvester_virtualmachine.outline, data.tailscale_device.outline]
}
