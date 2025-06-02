output "ipv4" {
  description = "Adresse IPv4 principale"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses[1][0]
}
