#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 2 ]; then
  echo "Usage: `basename $0` taille_vm nom_vm"
  exit $ERR_ARGS
fi

case $1 in
    xs|tiny|small|medium|large|xlarge)
        ;;
    *)
	echo "Usage: xs | tiny | small | medium | large | xlarge : $1";
	exit $ERR_ARGS;;
esac

# On fetch l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "#### Controleur : $ADR"

NOMSVMS=`ssh root@$ADR 'source openstack-openrc.sh && nova list' | cut -d '|' -f 3 | grep -o -E '(nvm_.+)'`;

# Vérifie que les noms des VMs soient différents
for NOMVM in $NOMSVMS; do
	if [ "$NOMVM" = "nvm_$2" ]; then
		echo "Le nom de la VM $2 existe déjà, veuillez en choisir un autre"
 		exit $ERR_ARGS
	fi
done

rake cmd cmd="
source openstack-openrc.sh;

VAR_RULE=\`nova secgroup-list-rules default | grep -o 10000\`;
if [ -z \"\$VAR_RULE\" ]; then
	echo 'Ajout des regles du parfeu'
        nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
        nova secgroup-add-rule default udp 10000 10100 0.0.0.0/0;
fi

echo '##### Creation de la VM';
nova boot --flavor m1.$1 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo nvm_$2;

echo '##### Creation de l IP publique';
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
\`sleep 3\`;
nova add-floating-ip nvm_$2 \$IP_PUB;
echo \$IP_PUB;

 " host=controller;

# On se connecte au controleur pour fetch l'IP de la VM
IP=`ssh root@$ADR 'source openstack-openrc.sh && nova list --name nvm_$2' | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;
sleep 3;
echo "##### Connexion à la VM pour MAJ : $IP"
ssh debian@$IP "sudo apt-get -y update; sudo apt-get -y install g++ gcc make;";

exit 0
