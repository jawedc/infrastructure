variable "name" {
  description = "Nom de la VM"
  type        = string
}

variable "node_name" {
  description = "Nom du nœud Proxmox (pve, pve2…) où créer la VM"
  type        = string
}

variable "cpu_cores" {
  description = "Nombre de cœurs"
  type        = number
}

variable "memory_mb" {
  description = "Mémoire dédiée (MiB)"
  type        = number
}

variable "disk_gb" {
  description = "Taille du disque (GiB)"
  type        = number
}

variable "file_id" {
  description = "volid de l'ISO ou du template (ex : local:iso/noble.img)"
  type        = string
}

variable "datastore_id" {
  description = "Datastore cible pour le disque (local-lvm, zfs-pool…)"
  type        = string
}

variable "user_data_file_id" {
  description = "ID du snippet cloud-init généré"
  type        = string
}

variable "bridge" {
  description = "Bridge réseau Proxmox (vmbr0…)"
  type        = string
}

variable "tags" {
  description = "Liste de tags Proxmox"
  type        = list(string)
}
