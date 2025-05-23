terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    private_key = file(var.ssh_private_key_path)
    username = "root"
  }
}

data "local_file" "ssh_pub" {
  filename = var.ssh_public_key_path
}

# Téléchargement de l'image — une ressource par VM
resource "proxmox_virtual_environment_download_file" "image" {
  for_each     = var.vm_configs
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = each.value.image_url
}

# Snippet cloud-init
resource "proxmox_virtual_environment_file" "user_data" {
  for_each     = var.vm_configs
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = templatefile("${path.root}/user-data.tpl.yaml", {
      hostname = each.key
      ssh_key  = trimspace(data.local_file.ssh_pub.content)
    })
    file_name = "${each.key}-user-data.yaml"
  }
}

# Création des VMs
resource "proxmox_virtual_environment_vm" "vm" {
  for_each  = var.vm_configs
  name      = each.key
  node_name = "pve"

  agent { enabled = true }

  cpu    { cores     = each.value.cpu_cores }
  memory { dedicated = each.value.memory_mb }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.image[each.key].id
    interface    = "virtio0"
    size         = each.value.disk_gb
    discard      = "on"
    iothread     = true
  }

  tags = each.value.tags

  initialization {
    ip_config {
      ipv4 { address = "dhcp" }
    }
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
  }

  network_device {
    bridge = "vmbr0"
  }
}

output "vm_ips" {
  description = "Map des noms de VM vers leur IPv4"
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm :
    name => vm.ipv4_addresses[1][0]
  }
}
