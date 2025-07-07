variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  sensitive   = true
}

variable "tailscale_api_key" {
  description = "Tailscale API key for authentication"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Email address of the admin user"
  type        = string
  sensitive = true
}
variable "admin_password" {
  description = "Password for the admin user"
  type        = string
}

variable "authentik_domain" {
  description = "URL of the Authentik instance"
  type        = string
  
}