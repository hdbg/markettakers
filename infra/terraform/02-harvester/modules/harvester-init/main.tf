resource "tailscale_oauth_client" "harvester" {
  description = "harvester operator client"
  scopes      = ["devices:core", "auth_keys"]
  tags        = ["tag:k8s-operator"]
}

locals {
  tailscale_chart_repo = "https://pkgs.tailscale.com/helmcharts" # stable channel [oai_citation:4‡tailscale.com](https://tailscale.com/kb/1236/kubernetes-operator)
}

resource "helm_release" "tailscale_operator" {
  name             = "tailscale-operator"
  namespace        = "tailscale"
  repository       = local.tailscale_chart_repo
  chart            = "tailscale-operator"
  create_namespace = true
  timeout          = 600

  atomic = true

  # Safer than ‘set { … }’ because of quoting issues in Helm + Terraform: [oai_citation:5‡github.com](https://github.com/tailscale/tailscale/issues/13074)
  # values = [templatefile("${path.module}/operator-values.yaml", {

  # })]

  set = [
    {
      name  = "oauth.clientId"
      value = tailscale_oauth_client.harvester.id
    },
    {
      name  = "oauth.clientSecret"
      value = tailscale_oauth_client.harvester.key
    }
  ]
}

resource "kubernetes_annotations" "harvester_dashboard_ts" {
  api_version = "v1"
  kind        = "Service"

  metadata {
    name      = "rancher"
    namespace = "cattle-system"
  }

  annotations = {
    "tailscale.com/expose"   = "true"
    "tailscale.com/hostname" = "harvester-ui"
  }

  field_manager   = "terraform"   # SSA field manager name
  force = true          # win if someone edits by hand
}

data "local_file" "local_ssh_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}



resource "harvester_ssh_key" "default" {
  name      = "admin"
  namespace = "default"

  public_key = data.local_file.local_ssh_key.content
}

resource "harvester_storageclass" "singlenode" {
  name = "singlenode"

  parameters = {
    "migratable"          = "true"
    "numberOfReplicas"    = "1"
    "staleReplicaTimeout" = "30"
  }

  is_default = true
}

resource "harvester_image" "fedora_42_cloud" {
  depends_on = [harvester_storageclass.singlenode]

  name      = "fedora-cloud-42"
  namespace = "harvester-public"

  display_name = "Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
  source_type  = "download"
  url          = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
}

resource "harvester_image" "fedora_42_workstation" {
  depends_on = [harvester_storageclass.singlenode]

  name      = "fedora-workstation-42"
  namespace = "harvester-public"

  display_name = "Fedora-Workstation-Live-42-1.1.x86_64.iso"
  source_type  = "download"
  url          = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Workstation/x86_64/iso/Fedora-Workstation-Live-42-1.1.x86_64.iso"
}

resource "tailscale_tailnet_key" "service-init-key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  description   = "Auto-provision key"
}

resource "harvester_cloudinit_secret" "cloud-init-service" {
  name      = "cloud-config-service"
  namespace = "default"

  depends_on = [
    harvester_ssh_key.default
  ]

  user_data    = <<-EOF
    #cloud-config
    ssh_pwauth: false
    package_update: true
    package_upgrade: true
    packages:
      - qemu-guest-agent
    ssh_authorized_keys:
      - >-
        ${harvester_ssh_key.default.public_key}
    write_files:
      - path: /usr/local/bin/setup-tailscale.sh
        permissions: '0755'
        content: |
          #!/usr/bin/env bash
          set -euo pipefail

          # install Tailscale
          curl -fsSL https://tailscale.com/install.sh | sh

          # bring up the interface using the auth key and hostname
          tailscale up \
            --authkey ${tailscale_tailnet_key.service-init-key.key} \
            --advertise-exit-node=false
    runcmd:
      - - systemctl
        - enable
        - '--now'
        - qemu-guest-agent
      - /usr/local/bin/setup-tailscale.sh
    EOF
  network_data = ""
}

data "harvester_clusternetwork" "mgmt" {
  name = "mgmt"
}
