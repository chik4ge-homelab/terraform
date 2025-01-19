locals {
  common_machine_config = {
    machine = {
      install = {
        image = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:${local.talos_version}"
      }
      #   features = {
      #     kubePrism = {
      #       enabled = true
      #       port    = 7445
      #     }
      #     hostDNS = {
      #       enabled              = true
      #       forwardKubeDNSToHost = true
      #     }
      #   }
    }
    # cluster = {
    #   discovery = {
    #     enabled = true
    #     registries = {
    #       kubernetes = {
    #         disabled = true
    #       }
    #       service = {
    #         disabled = true
    #       }
    #     }
    #   }
    #   network = {
    #     cni = {
    #       name = "none"
    #     }
    #   }
    #   proxy = {
    #     disabled = true
    #   }
    # }
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for node in var.control_planes : node.name]
  endpoints            = [for node in var.control_planes : node.ip]
}

data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.cluster_vip}:6443"
  #   cluster_endpoint = "https://${var.control_planes[0].ip}:6443"
  machine_secrets = talos_machine_secrets.this.machine_secrets

  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              deviceSelector = {
                physical = true
              }
              vip = {
                ip = var.cluster_vip
              }
            }
          ]
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name = var.cluster_name
  machine_type = "worker"
  #   cluster_endpoint = "https://${var.cluster_vip}:6443"
  cluster_endpoint = "https://${var.control_planes[0].ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [
    yamlencode(local.common_machine_config),
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = var.control_planes[0].name
  endpoint             = var.control_planes[0].ip
  depends_on           = [talos_machine_bootstrap.this]
}

resource "talos_machine_configuration_apply" "control_plane" {
  count = length(var.control_planes)

  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = var.control_planes[count.index].name

  endpoint   = var.control_planes[count.index].ip
  depends_on = [proxmox_virtual_environment_vm.control_planes]
}

resource "talos_machine_configuration_apply" "worker" {
  count = length(var.workers)

  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.workers[count.index].name

  endpoint   = var.workers[count.index].ip
  depends_on = [proxmox_virtual_environment_vm.workers]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = var.control_planes[0].name
  endpoint             = var.control_planes[0].ip
  depends_on           = [talos_machine_configuration_apply.control_plane]
}
