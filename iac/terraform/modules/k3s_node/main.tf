######################################
# Module : k3s_node
# Crée UNE VM prête pour K3s sur Proxmox
######################################

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name

  agent { enabled = true }

  cpu    { cores     = var.cpu_cores }
  memory { dedicated = var.memory_mb }

  disk {
    datastore_id = var.datastore_id
    file_id      = var.file_id
    interface    = "virtio0"
    size         = var.disk_gb
    discard      = "on"
    iothread     = true
  }

  tags = var.tags

  initialization {
    ip_config { 
      ipv4 { 
        address = "dhcp" 
      } 
    }
    user_data_file_id = var.user_data_file_id
  }

  network_device { bridge = var.bridge }
}
