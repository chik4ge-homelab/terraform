# Proxmox VE settings
variable "pve_user" {
  description = "The username for the proxmox user"
  type        = string
  sensitive   = false
}
variable "pve_password" {
  description = "The password for the proxmox user"
  type        = string
  sensitive   = true
}
variable "pve_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = true
}
variable "pve_host" {
  description = "The hostname or IP of the proxmox server"
  type        = string
  default     = "192.168.0.150:8006"
}

# network variables
variable "network_mask" {
  description = "The subnet mask for the VMs"
  type        = string
  default     = "22"
}
variable "network_gateway" {
  description = "The network gateway for the VMs"
  type        = string
  default     = "192.168.0.1"
}

# Talos variables
variable "talos_version" {
  description = "The version of Talos to use"
  type        = string
  default     = "v1.9.4" # renovate: datasource=github-releases packageName=siderolabs/talos
}

variable "control_planes" {
  description = "settings for k8s control planes"
  type = list(
    object({
      name          = string
      vm_id         = number
      pve_node_name = string
      ip            = string
      memory        = optional(number, 4 * 1024) # 4GB
      cpu_sockets   = optional(number, 1)
      cpu_cores     = optional(number, 4)
      disk_size     = optional(number, 20) # 20GB
    })
  )
  default = [
    {
      name          = "k8s-cp-argon"
      vm_id         = 101
      pve_node_name = "host01"
      ip            = "192.168.1.101"
    },
    {
      name          = "k8s-cp-boron"
      vm_id         = 102
      pve_node_name = "host02"
      ip            = "192.168.1.102"
    },
    {
      name          = "k8s-cp-carbon"
      vm_id         = 104
      pve_node_name = "host01"
      ip            = "192.168.1.103"
    },
  ]
}

variable "workers" {
  description = "settings for k8s worker nodes"
  type = list(
    object({
      name          = string
      vm_id         = number
      pve_node_name = string
      ip            = string
      memory        = optional(number, 10 * 1024) # 10GB
      cpu_sockets   = optional(number, 1)
      cpu_cores     = optional(number, 4)
      disk_size     = optional(number, 130) # 130GB
    })
  )
  default = [
    {
      name          = "k8s-w-anemone"
      vm_id         = 201
      pve_node_name = "host01"
      ip            = "192.168.1.201"
      memory        = 8 * 1024 # 16GB
      disk_size     = 64       # 64GB
    },
    {
      name          = "k8s-w-blossom"
      vm_id         = 202
      pve_node_name = "host01"
      ip            = "192.168.1.202"
      memory        = 8 * 1024 # 8GB
      disk_size     = 64       # 64GB
    },
    {
      name          = "k8s-w-clover"
      vm_id         = 203
      pve_node_name = "host02"
      ip            = "192.168.1.203"
      disk_size     = 64 # 64GB
    },
    {
      name          = "k8s-w-daisy"
      vm_id         = 204
      pve_node_name = "host02"
      ip            = "192.168.1.204"
      memory        = 8 * 1024 # 8GB
      disk_size     = 64       # 64GB
    },
  ]
}
