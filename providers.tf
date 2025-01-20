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

    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre1"
    }

    argocd = {
      source  = "dcoppa/argocd"
      version = "6.1.0-46"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.pve_host}/"
  username = var.pve_user
  password = var.pve_password
  insecure = var.pve_tls_insecure
}

provider "helm" {
  kubernetes = {
    host = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host

    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}

provider "argocd" {
  port_forward = true
  kubernetes {
    host = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host

    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}
