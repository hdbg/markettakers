data "authentik_flow" "default_implicit_flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_explicit_flow" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-invalidation-flow"
}

resource "authentik_group" "worker" {
  name         = "worker"
}


resource "authentik_group" "boss" {
  name         = "boss"
  is_superuser = true
}

resource "authentik_provider_rac" "vm" {
  name      = "vm"
  authorization_flow = data.authentik_flow.default_implicit_flow.id
}

resource "authentik_application" "vm" {
  name              = "Virtual Machine Access"
  slug              = "vm-access"
  protocol_provider = authentik_provider_rac.vm.id
}