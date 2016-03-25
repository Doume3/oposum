#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 2 ]
then
  echo "Usage: `basename $0` taille_vm nom_vm"
  exit $ERR_ARGS
fi

case $1 in
    xs|tiny|small|medium|large|xlarge)
        echo "Flavor : $1";;
    *)
	echo "Usage: xs | tiny | small | medium | large | xlarge : $1";
	exit $ERR_ARGS;;
esac

echo '#+------------------------+';
echo '#|        VM_SETUP        |';
echo '#+------------------------+';

rake cmd cmd="echo '#### START_RAKE ####';
source openstack-openrc.sh;

echo '#### CREATION VM ####';
nova boot --flavor m1.$1 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo $2;

echo '#### AJOUTE IP PUBLIQUE ####';
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
\`sleep 2\`;
nova add-floating-ip $2 \$IP_PUB;
echo \$IP_PUB;

echo '#### MODIFIE DROITS ####';
VAR_RULE=\`(nova secgroup-list-rules default | grep -o 10000)\`;

if [ -z \$VAR_RULE ]
then
	nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
	nova secgroup-add-rule default udp 10000 10100 0.0.0.0/0;
fi
 " host=controller;


#On fetch l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "*Adresse du controller* > $ADR";

#On s'y connecte pour fetch la liste des IP_VM
IP=`ssh root@$ADR 'source openstack-openrc.sh && nova list --name $2' | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;
echo "#### IP VM > $IP ####";

echo "#### VM : $IP ####";

ssh debian@$IP "sudo apt-get -y update;";

echo '#### VM installe ####';