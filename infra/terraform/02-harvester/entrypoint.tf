provider "tailscale" {
  api_key = var.tailscale_api_key
}

provider "harvester" {
  kubeconfig = var.kubeconfig_path
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

resource "tailscale_acl" "as_json" {
  acl = jsonencode({
    acls : [
      {
        // Allow all users access to all ports.
        action = "accept",
        users  = ["*"],
        ports  = ["*:*"],
      },
    ],

    tagOwners: {
      "tag:k8s-operator" = [],
      "tag:k8s" = ["tag:k8s-operator"],
    }
  })
}


module "harvester-init" {
  depends_on = [ tailscale_acl.as_json ]

  source = "./modules/harvester-init"

  providers = {
    tailscale  = tailscale
    harvester  = harvester
    kubernetes = kubernetes
    helm       = helm

  }
}

module "directus" {
  source = "./modules/directus"

  providers = {
    tailscale  = tailscale
    harvester  = harvester
  }

  admin_email = var.admin_email
  admin_password = var.admin_password
  fedora_cloud_42_image       = module.harvester-init.fedora_cloud_42_image
  cloud_init_service_secret   = module.harvester-init.cloud_init_service_secret
}