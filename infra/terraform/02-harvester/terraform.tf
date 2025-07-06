terraform {
  required_providers {
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.6"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.6.0"
    }
    harvester = {
      source  = "harvester/harvester"
      version = "0.6.7"
    }
    tailscale = {
        source = "tailscale/tailscale"
        version = "~> 0.21.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
  }
}

