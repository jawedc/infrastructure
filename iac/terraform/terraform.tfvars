
vm_configs = {
  "k3s-agent2" = {
    cpu_cores    = 2
    memory_mb    = 8192
    disk_gb      = 300
    image_url    = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    # Nom du template user-data placé à la racine
    cloud_init_tpl = "user-data.tpl.yaml"
    tags         = ["ubuntu", "k3s-agent", "k3s-cluster"]
  }
  "k3s-agent1" = {
    cpu_cores    = 2
    memory_mb    = 8192
    disk_gb      = 300
    image_url    = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    # Nom du template user-data placé à la racine
    cloud_init_tpl = "user-data.tpl.yaml"
    tags         = ["ubuntu", "k3s-agent", "k3s-cluster"]
  }
  "k3s-master" = {
    cpu_cores    = 2
    memory_mb    = 4096
    disk_gb      = 100
    image_url    = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    # Nom du template user-data placé à la racine
    cloud_init_tpl = "user-data.tpl.yaml"
    tags         = ["ubuntu", "k3s-master", "k3s-cluster"]
  }
}
