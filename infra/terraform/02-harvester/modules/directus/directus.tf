resource "harvester_virtualmachine" "directus" {
  name      = "directus"
  namespace = "default"

  tags = {
    ssh-user = "fedora"
    service  = "directus"
  }

  cpu    = 2
  memory = "4Gi"

  efi         = true
  secure_boot = true

  network_interface {
    name = "nic-1"
    type = "bridge"
  }

  disk {
    name       = "cdrom-disk"
    type       = "disk"
    size       = "20Gi"
    bus        = "virtio"
    boot_order = 1

    image = var.fedora_cloud_42_image
  }

  cloudinit {
    user_data_secret_name = var.cloud_init_service_secret
  }
}

data "tailscale_device" "directus" {
  depends_on = [ harvester_virtualmachine.directus ]

  hostname = harvester_virtualmachine.directus.name
  wait_for = "360s"
}

resource "random_password" "pg_pass" {
  length  = 32
  special = false
}
resource "random_password" "directus_secret" {
  length  = 64
  special = false
}



resource "ansible_playbook" "directus_cfg" {
  name       = data.tailscale_device.directus.addresses[0]
  playbook   = "../../ansible/playbooks/directus.yml"
  replayable = true

  extra_vars = {
    public_url = data.tailscale_device.directus.name
    pg_pass    = random_password.pg_pass.result
    directus_secret = random_password.directus_secret.result
    admin_email = var.admin_email
    admin_password = var.admin_password
  }

  depends_on = [harvester_virtualmachine.directus, data.tailscale_device.directus]
}
