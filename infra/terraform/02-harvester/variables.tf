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