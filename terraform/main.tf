terraform {
  required_providers {
    # Ganti dengan provider cloud kamu: aws, google, azurerm, openstack, proxmox
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "http://10.10.101.204:8006/api2/json"  # ganti IP Proxmox kamu
  pm_api_token_id     = "root@pam!terraform!terraform"     # ganti token ID
  pm_api_token_secret = "ee19335f-4431-400c-b95b-5400fa0a2402"  # ganti secret
  pm_tls_insecure     = false   # set false jika pakai SSL cert valid
}

resource "proxmox_vm_qemu" "monitored_vm" {
  count       = 10
  name        = format("vm-%03d", count.index + 1)    # vm-001, vm-002, ... vm-100
  target_node = "pve-node-01"
  clone       = "ubuntu-22.04-template"               # golden image yang sudah disiapkan
  
  cores   = 2
  memory  = 2048
  
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init: inject SSH key & set hostname otomatis
  os_type    = "cloud-init"
  ipconfig0  = "ip=dhcp"
  sshkeys    = file("~/.ssh/id_ed25519.pub")
  ciuser     = "ubuntu"

  tags = "monitored,node-exporter"
}

# Output: generate file inventory Ansible otomatis
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    vms = proxmox_vm_qemu.monitored_vm[*]
  })
  filename = "../ansible/inventory/hosts.ini"
}

# Output: generate file targets Prometheus otomatis
resource "local_file" "prometheus_targets" {
  content = jsonencode([
    {
      targets = [for vm in proxmox_vm_qemu.monitored_vm : "${vm.default_ipv4_address}:9100"]
      labels  = { job = "node_exporter", env = "production" }
    }
  ])
  filename = "../prometheus/targets/nodes.json"
}