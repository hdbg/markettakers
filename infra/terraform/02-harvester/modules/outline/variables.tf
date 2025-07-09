variable "fedora_cloud_42_image" {
    description = "ID of the Fedora Cloud 42 image"
    type        = string
    default     = ""
}


variable "cloud_init_service_secret" {
    description = "Name of the cloud-init secret for service VMs"
    type        = string
    default     = "cloud-config-service"
}

variable "authentik_domain" {
  description = "URL of the Authentik instance"
  type        = string
}