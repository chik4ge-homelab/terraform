terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.0"
    }
    
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_host}/"
  username = var.pve_user
  password = var.pve_password
  insecure = var.pve_tls_insecure
}
