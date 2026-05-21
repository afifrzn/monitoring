[all_vms]
%{ for vm in vms ~}
${vm.name} ansible_host=${one([for iface in vm.ipv4_addresses : one([for ip in iface : ip if ip != "127.0.0.1"])])} ansible_user=ubuntu
%{ endfor ~}

[all_vms:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3