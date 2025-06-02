terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      # version non requise ici : celle du root (0.78.0) s’impose
    }
  }
}
