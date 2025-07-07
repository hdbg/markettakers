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
  name = "worker"
}

data "authentik_brand" "default" {
  domain = "authentik-default"
}

resource "authentik_brand" "default" {
  domain           = "authentik-default" # ← this is the built-in brand’s domain
  default          = false
  branding_logo    = data.authentik_brand.default.branding_logo
  branding_favicon = data.authentik_brand.default.branding_favicon
  branding_title   = data.authentik_brand.default.branding_title
}

resource "authentik_brand" "markettakers" {
  depends_on = [authentik_brand.default]

  domain           = "."
  default          = true
  branding_title   = "MarketTakers"
  branding_logo    = "./media/logo.png"
  branding_favicon = "./media/favicon.ico"
}

data "authentik_user" "admin" {
  username = "akadmin"
}

resource "authentik_group" "boss" {
  name  = "Boss"
  users = [data.authentik_user.admin.id]

  is_superuser = true
}

resource "authentik_provider_rac" "vm" {
  name               = "vm"
  authorization_flow = data.authentik_flow.default_implicit_flow.id
}

resource "authentik_application" "vm" {
  name              = "Virtual Machine Access"
  slug              = "vm-access"
  protocol_provider = authentik_provider_rac.vm.id
}
