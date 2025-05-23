# variables.tf

variable "proxmox_endpoint" {
  description = "URL du serveur Proxmox"
  type        = string
  default     = "https://192.168.1.44:8006"
}

variable "proxmox_api_token" {
  description = "Token API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Autoriser TLS auto-signé"
  type        = bool
  default     = true
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "/root/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Chemin vers la clé SSH privee"
  type        = string
  default     = "/root/.ssh/id_ed25519"
}

variable "vm_configs" {
  description = "Map des VMs avec leurs ressources et image"
  type = map(object({
    cpu_cores    = number
    memory_mb    = number
    disk_gb      = number
    image_url    = string
    tags         = list(string)
  }))
  default = {
    "ubuntu-01" = {
      cpu_cores = 2
      memory_mb = 2048
      disk_gb   = 20
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      tags      = ["ubuntu","ansible"]
    }
    "ubuntu-02" = {
      cpu_cores = 4
      memory_mb = 4096
      disk_gb   = 40
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      tags      = ["ubuntu","db"]
    }
  }
}

