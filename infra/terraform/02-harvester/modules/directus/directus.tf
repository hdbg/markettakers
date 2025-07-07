resource "harvester_virtualmachine" "directus" {
  name      = "directus"
  namespace = "default"

  tags = {
    ssh-user = "fedora"
    service  = "directus"
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

data "tailscale_device" "directus" {
  depends_on = [harvester_virtualmachine.directus]

  hostname = harvester_virtualmachine.directus.name
  wait_for = "360s"
}

resource "random_password" "pg_pass" {
  length  = 32
  special = false
}
resource "random_password" "directus_secret" {
  length  = 64
  special = false
}

data "authentik_property_mapping_provider_scope" "directus" {
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


resource "authentik_provider_oauth2" "directus" {
  depends_on = [harvester_virtualmachine.directus, data.tailscale_device.directus]

  name               = "Directus"
  client_id          = "directus"
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
  authorization_flow = data.authentik_flow.default_explicit_flow.id
  client_type        = "confidential"
  property_mappings  = data.authentik_property_mapping_provider_scope.directus.ids
  allowed_redirect_uris = [
    {
      matching_mode = "regex",
      url           = ".*",
    }
  ]

  sub_mode = "user_username"

  signing_key = data.authentik_certificate_key_pair.generated.id
}

resource "authentik_application" "directus" {
  name              = "Directus"
  slug              = "directus"
  protocol_provider = authentik_provider_oauth2.directus.id
}

resource "ansible_playbook" "directus_cfg" {
  name       = data.tailscale_device.directus.addresses[0]
  playbook   = "../../ansible/playbooks/directus.yml"
  replayable = true

  extra_vars = {
    public_url      = data.tailscale_device.directus.name
    pg_pass         = random_password.pg_pass.result
    directus_secret = random_password.directus_secret.result
    admin_email     = var.admin_email
    admin_password  = var.admin_password

    sso_client_id     = authentik_provider_oauth2.directus.client_id
    sso_client_secret = authentik_provider_oauth2.directus.client_secret
    sso_issuer_url    = "https://${var.authentik_domain}/application/o/${authentik_provider_oauth2.directus.client_id}"
  }

  force_handlers = true

  depends_on = [harvester_virtualmachine.directus, data.tailscale_device.directus]
}
