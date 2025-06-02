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
  description = "Ignorer le TLS auto-signé"
  type        = bool
  default     = true
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519"
}
