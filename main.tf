terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_host}/"
  username = var.pve_user
  password = var.pve_password
  insecure = var.pve_tls_insecure
}

locals {
  pve_nodes = distinct(
    concat(
      [for control_node in var.control_nodes : control_node.pve_node_name],
      [for worker_node in var.worker_nodes : worker_node.pve_node_name]
    )
  )
  talos_version = "v1.9.2"
}

resource "proxmox_virtual_environment_download_file" "talos_cloud_image" {
  count = length(local.pve_nodes)
  node_name = local.pve_nodes[count.index]
  content_type = "iso"
  datastore_id = "local"
  url = "https://github.com/siderolabs/talos/releases/download/${local.talos_version}/metal-amd64.iso"
  file_name = "talos-${local.talos_version}.iso"
}
