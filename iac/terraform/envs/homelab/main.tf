###############################################
# 0. Providers
###############################################
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint    = var.proxmox_endpoint
  api_token   = var.proxmox_api_token
  insecure    = var.proxmox_insecure
  ssh {
    private_key = file(var.ssh_private_key_path)
    username    = "root"
    agent       = true
  }
}

###############################################
# 1. Téléchargement ISO si nécessaire
###############################################
data "http" "isos" {
  url = "${var.proxmox_endpoint}/api2/json/nodes/pve/storage/local/content?content=iso"
  request_headers = {
    Authorization = "PVEAPIToken=${var.proxmox_api_token}"
  }
  insecure = var.proxmox_insecure
}

locals {
  iso_volids = [
    for m in regexall("\"volid\"\\s*:\\s*\"([^\"]+)\"", data.http.isos.response_body) :
    m[0]
  ]
  existing_iso_names = toset([ for v in local.iso_volids : replace(v, "local:iso/", "") ])

  # Les 3 VMs de notre cluster
  vm_definitions = {
    k3s-master = {
      cpu_cores = 2
      memory_mb = 4096
      disk_gb   = 100
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      tags      = ["ubuntu","k3s-master","k3s-cluster"]
    }
    k3s-agent1 = {
      cpu_cores = 2
      memory_mb = 8192
      disk_gb   = 300
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      tags      = ["ubuntu","k3s-agent","k3s-cluster"]
    }
    k3s-agent2 = {
      cpu_cores = 2
      memory_mb = 8192
      disk_gb   = 300
      image_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      tags      = ["ubuntu","k3s-agent","k3s-cluster"]
    }
  }

  download_needed = {
    for name, cfg in local.vm_definitions :
    name => cfg if !contains(local.existing_iso_names, basename(cfg.image_url))
  }

  vm_image_ids = {
    for name, cfg in local.vm_definitions :
    name => (
      contains(keys(proxmox_virtual_environment_download_file.image), name)
      ? proxmox_virtual_environment_download_file.image[name].id
      : "local:iso/${basename(cfg.image_url)}"
    )
  }
}

resource "proxmox_virtual_environment_download_file" "image" {
  for_each     = local.download_needed
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = each.value.image_url
  overwrite           = false
  overwrite_unmanaged = false
}

###############################################
# 2. Snippets cloud-init
###############################################
resource "proxmox_virtual_environment_file" "user_data" {
  for_each     = local.vm_definitions
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"
  source_raw {
    data = templatefile("${path.module}/user-data.tpl.yaml", {
      hostname = each.key
      ssh_key  = trimspace(file(var.ssh_public_key_path))
    })
    file_name = "${each.key}-user-data.yaml"
  }
}

###############################################
# 3. Appels au module k3s_node
###############################################
module "k3s_nodes" {
  for_each = local.vm_definitions
  source   = "../../modules/k3s_node"

  name              = each.key
  node_name         = "pve"
  cpu_cores         = each.value.cpu_cores
  memory_mb         = each.value.memory_mb
  disk_gb           = each.value.disk_gb
  datastore_id      = "local-lvm"
  bridge            = "vmbr0"
  file_id           = local.vm_image_ids[each.key]
  user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
  tags              = each.value.tags
}

###############################################
# 4. Sortie des IPs
###############################################
output "k3s_node_ips" {
  value = { for n, mod in module.k3s_nodes : n => mod.ipv4 }
}
