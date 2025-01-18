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
  default     = "192.168.0.150:8006" # TODO: change to my domain and pass cf access headers
}

variable "vm_ip_mask" {
  description = "The IP mask for the VMs"
  type        = string
  default     = "22"
}

variable "network_gateway" {
  description = "The network gateway for the VMs"
  type        = string
  default     = "192.168.0.1"
}

variable "control_planes" {
  description = "settings for k8s control planes"
  type = list(
    object({
      name          = string
      vm_id         = number
      pve_node_name = string
      ip            = string
      memory        = optional(string, 6 * 1024) # 6GB
      cpu_sockets   = optional(number, 1)
      cpu_cores     = optional(number, 2)
      disk_size     = optional(number, 100) # 100GB
    })
  )
  default = [
    # {
    #   name         = "k8s-cp-argon"
    #   vm_id         = 101
    #   pve_node_name = "host01"
    #   ip           = "192.168.1.101"
    # },
    {
      name          = "k8s-cp-boron"
      vm_id         = 102
      pve_node_name = "host02"
      ip            = "192.168.1.102"
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
      memory        = optional(string, 10 * 1024)
      cpu_sockets   = optional(number, 1)
      cpu_cores     = optional(number, 2)
      disk_size     = optional(number, 100) # 100GB
    })
  )
  default = [
    # {
    #   name         = "k8s-w-anemone"
    #   vm_id         = 201
    #   pve_node_name = "host01"
    #   ip           = "192.168.1.201"
    # },
    # {
    #   name         = "k8s-c-blossom"
    #   vm_id         = 202
    #   pve_node_name = "host01"
    #   ip           = "192.168.1.202"
    # },
    # {
    #   name         = "k8s-c-clover"
    #   vm_id         = 203
    #   pve_node_name = "host02"
    #   ip           = "192.168.1.203"
    # },
    # {
    #   name         = "k8s-c-daisy"
    #   vm_id         = 204
    #   pve_node_name = "host02"
    #   ip           = "192.168.1.204"
    # },
  ]
}
