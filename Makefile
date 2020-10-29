packer:
	ansible-playbook playbooks/create_ami.yml -i inventories/development -vvv

infra:
	ansible-playbook playbooks/create_infrastructure.yml -i inventories/development -vvv

ssh:
	 ssh-keygen -f "/home/vagrant/.ssh/known_hosts" -R "3.17.124.68"
	 ssh -i ~/.ssh/sf.pem ubuntu@3.17.124.68
