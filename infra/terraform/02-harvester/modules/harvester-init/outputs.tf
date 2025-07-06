output "fedora_cloud_42_image" {
  value = harvester_image.fedora_42_cloud.id
}

output "fedora_workstation_42_image" {
  value = harvester_image.fedora_42_workstation.id
}

output "cloud_init_service_secret" {
  value = harvester_cloudinit_secret.cloud_init_service.name
}

