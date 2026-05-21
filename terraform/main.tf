terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://10.10.101.204:8006"
  api_token = "root@pam!terraform-token=42eb4495-904a-4767-acdb-ea29657933b5"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "monitored_vm" {
  count     = 2
  name      = format("vm-%03d", count.index + 1)
  node_name = "node4"

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "ubuntu"
      keys     = [file("~/.ssh/id_ed25519.pub")]
    }
  }

  timeout_clone  = 300
  timeout_create = 300

  tags = ["monitored", "node-exporter"]
}

output "vm_names" {
  value = [for vm in proxmox_virtual_environment_vm.monitored_vm : vm.name]
}