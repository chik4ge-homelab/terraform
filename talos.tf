locals {
  common_machine_config = {
    machine = {
      install = {
        image = "factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:${var.talos_version}"
      }
      features = {
        kubePrism = {
          enabled = true
          port    = 7445
        }
        hostDNS = {
          enabled              = true
          forwardKubeDNSToHost = true
        }
      }
    }
    cluster = {
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = var.control_planes[*].ip
}

data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_planes[0].ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

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
      # https://www.talos.dev/v1.9/kubernetes-guides/configuration/storage/#prep-nodes
      cluster = {
        apiServer = {
          admissionControl = [{
            name = "PodSecurity"
            configuration = {
              apiVersion = "pod-security.admission.config.k8s.io/v1beta1"
              kind       = "PodSecurityConfiguration"
              exemptions = {
                namespaces = ["openebs"]
              }
            }
          }]
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.control_planes[0].ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = [
    yamlencode(local.common_machine_config),
    yamlencode({
      machine = {
        # https://www.talos.dev/v1.9/kubernetes-guides/configuration/storage/#prep-nodes
        sysctls = {
          "vm.nr_hugepages" = "1024"
        }
        nodeLabels = {
          "openebs.io/engine" = "mayastor"
        }
        disks = [
          {
            device     = "/dev/sdb"
          }
        ]
        kubelet = {
          extraMounts = [
            {
              destination = "/var/local"
              type        = "bind"
              source      = "/var/local"
              options = [
                "rbind",
                "rshared",
                "rw",
              ]
            },
          ]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "control_plane" {
  depends_on = [
    proxmox_virtual_environment_vm.control_planes
  ]

  count = length(var.control_planes)

  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = var.control_planes[count.index].ip

  endpoint = var.control_planes[count.index].ip
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    proxmox_virtual_environment_vm.workers
  ]

  count = length(var.workers)

  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = var.workers[count.index].ip

  endpoint = var.workers[count.index].ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.control_plane,
    talos_machine_configuration_apply.worker
  ]

  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = var.control_planes[0].ip
  endpoint             = var.control_planes[0].ip
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = data.talos_client_configuration.this.client_configuration
  node                 = var.control_planes[0].ip
  endpoint             = var.cluster_vip
}

data "talos_cluster_health" "without_k8s" {
  depends_on = [
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]

  skip_kubernetes_checks = true
  client_configuration   = data.talos_client_configuration.this.client_configuration
  control_plane_nodes    = var.control_planes[*].ip
  worker_nodes           = var.workers[*].ip
  endpoints              = var.control_planes[*].ip
}
