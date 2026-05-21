# terraform/inventory.tpl  (template untuk Ansible inventory)
[all_vms]
%{ for vm in vms ~}
${vm.name} ansible_host=${vm.default_ipv4_address} ansible_user=ubuntu
%{ endfor ~}

[all_vms:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3