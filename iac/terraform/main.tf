terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  endpoint    = var.proxmox_endpoint
  api_token   = var.proxmox_api_token
  insecure    = var.proxmox_insecure

  ssh {
    agent       = true
    private_key = file(var.ssh_private_key_path)
    username    = "root"
  }
}

# 1. Récupère la liste des ISO existants via l'API Proxmox (HTTP data source)
data "http" "isos" {
  url = "${var.proxmox_endpoint}/api2/json/nodes/pve/storage/local/content?content=iso"
  request_headers = {
    Authorization = "PVEAPIToken=${var.proxmox_api_token}"
  }
  insecure = var.proxmox_insecure
}

# 2. Clé SSH publique pour cloud-init
data "local_file" "ssh_pub" {
  filename = var.ssh_public_key_path
}

# 3. Locals pour filtrer et construire les mappings
locals {
  # 3.1 Liste brute de tous les "volid" trouvés dans la réponse JSON
  iso_volids = [
    for m in regexall("\"volid\"\\s*:\\s*\"([^\"]+)\"", data.http.isos.response_body) :
    m[0]
  ]

  # 3.2 Noms d'ISO sans le préfixe "local:iso/"
  existing_iso_names = toset([
    for v in local.iso_volids :
    replace(v, "local:iso/", "")
  ])

  # 3.3 Liste des VMs à télécharger (ISO manquants)
  download_list = {
    for vm_name, cfg in var.vm_configs :
    vm_name => cfg
    if !contains(local.existing_iso_names, basename(cfg.image_url))
  }

  # 3.4 Mapping VM → file_id (soit nouvellement téléchargé, soit existant)
  vm_image_ids = {
    for vm_name, cfg in var.vm_configs :
    vm_name => (
      contains(keys(proxmox_virtual_environment_download_file.image), vm_name)
      ? proxmox_virtual_environment_download_file.image[vm_name].id
      : "local:iso/${basename(cfg.image_url)}"
    )
  }
}

# 4. Télécharger uniquement les ISO absents
resource "proxmox_virtual_environment_download_file" "image" {
  for_each     = local.download_list
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = each.value.image_url

  overwrite           = false
  overwrite_unmanaged = false
}

# 5. Génération des snippets cloud-init
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

# 6. Création des VMs
resource "proxmox_virtual_environment_vm" "vm" {
  for_each  = var.vm_configs
  name      = each.key
  node_name = "pve"

  agent { enabled = true }

  cpu    { cores     = each.value.cpu_cores }
  memory { dedicated = each.value.memory_mb }

  disk {
    datastore_id = "local-lvm"
    file_id      = local.vm_image_ids[each.key]
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

# 7. Sortie des adresses IPv4
output "vm_ips" {
  description = "Map des noms de VM vers leur IPv4"
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm :
    name => vm.ipv4_addresses[1][0]
  }
}
