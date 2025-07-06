# resource "harvester_virtualmachine" "directus" {
#   name      = "directus"
#   namespace = "default"

#   tags = {
#     ssh-user = "fedora"
#     service  = "directus"
#   }

#   cpu    = 2
#   memory = "4Gi"

#   efi         = true
#   secure_boot = true

#   network_interface {
#     name = "nic-1"
#     type = "bridge"
#   }

#   ssh_keys = [harvester_ssh_key.default.id]

#   disk {
#     name       = "cdrom-disk"
#     type       = "disk"
#     size       = "20Gi"
#     bus        = "virtio"
#     boot_order = 1

#     image = harvester_image.fedora_42_cloud.id
#   }

#   cloudinit {
#     user_data_secret_name = harvester_cloudinit_secret.cloud-init-service.name
#   }
# }

# data "tailscale_device" "directus" {
#   hostname = "directus"
#   wait_for = "180s"
# }

# resource "ansible_playbook" "authentik-cfg" {
#   name       = data.tailscale_device.directus.name
#   playbook   = "../ansible/playbooks/directus.yml"
#   replayable = true

#   extra_vars = {
#   }

#   depends_on = [tailscale_device.directus]
# }
