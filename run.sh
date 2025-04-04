set -a
source .env
set +a

ansible-playbook -i inventory.ini playbook.yml
