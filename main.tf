locals {
  pve_nodes = distinct(
    concat(
      [for control_node in var.control_planes : control_node.pve_node_name],
      [for worker_node in var.workers : worker_node.pve_node_name]
    )
  )

  # Map to associate node names with the corresponding talos_cloud_image index
  node_to_image_index = {
    for idx, node in local.pve_nodes : node => idx
  }

  talos_iso_url       = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/${var.talos_version}/nocloud-amd64.iso"
  talos_iso_file_name = "talos-${var.talos_version}-nocloud-amd64.iso"
}

resource "proxmox_virtual_environment_download_file" "talos_cloud_images" {
  count = length(local.pve_nodes)

  node_name           = local.pve_nodes[count.index]
  content_type        = "iso"
  datastore_id        = "local"
  url                 = local.talos_iso_url
  file_name           = local.talos_iso_file_name
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "control_planes" {
  count = length(var.control_planes)

  name        = var.control_planes[count.index].name
  description = "Managed by Terraform"
  tags        = sort(["kubernetes", "k8s-control"])

  bios            = "ovmf"
  machine         = "q35"
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }

  node_name = var.control_planes[count.index].pve_node_name
  vm_id     = var.control_planes[count.index].vm_id

  cpu {
    sockets = var.control_planes[count.index].cpu_sockets
    cores   = var.control_planes[count.index].cpu_cores
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.control_planes[count.index].memory
  }

  tpm_state {
    version = "v2.0"
  }

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = var.control_planes[count.index].disk_size
    file_id      = proxmox_virtual_environment_download_file.talos_cloud_images[local.node_to_image_index[var.control_planes[count.index].pve_node_name]].id
  }

  agent {
    enabled = true
    trim    = true
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.control_planes[count.index].ip}/${var.network_mask}"
        gateway = var.network_gateway
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  count = length(var.workers)

  name        = var.workers[count.index].name
  description = "Managed by Terraform"
  tags        = sort(["kubernetes", "k8s-worker"])

  bios            = "ovmf"
  machine         = "q35"
  stop_on_destroy = true
  scsi_hardware   = "virtio-scsi-single"
  operating_system {
    type = "l26"
  }

  node_name = var.workers[count.index].pve_node_name
  vm_id     = var.workers[count.index].vm_id

  cpu {
    sockets = var.workers[count.index].cpu_sockets
    cores   = var.workers[count.index].cpu_cores
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.workers[count.index].memory
  }

  tpm_state {
    version = "v2.0"
  }

  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = var.workers[count.index].disk_size
    file_id      = proxmox_virtual_environment_download_file.talos_cloud_images[local.node_to_image_index[var.workers[count.index].pve_node_name]].id
  }

  agent {
    enabled = true
    trim    = true
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.workers[count.index].ip}/${var.network_mask}"
        gateway = var.network_gateway
      }
    }
  }
}
