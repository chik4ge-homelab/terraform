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

    cilium = {
      source = "littlejo/cilium"
      version = "0.2.15-rc1"
    }
    
    helm = {
      source = "hashicorp/helm"
      version = "3.0.0-pre1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_host}/"
  username = var.pve_user
  password = var.pve_password
  insecure = var.pve_tls_insecure
}

provider "cilium" {
  config_content = base64encode(talos_cluster_kubeconfig.this.kubeconfig_raw)
}

provider "helm"{
  kubernetes = {
    host     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host

    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}
