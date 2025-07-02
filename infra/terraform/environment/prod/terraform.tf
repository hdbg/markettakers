terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.6.0"
    }
  }
}

