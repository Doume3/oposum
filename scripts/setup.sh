#!/bin/bash

# PRE-REQUIS : scp un dossier d'applications (Serveur/) sur votre frontend.

ERR_ARGS=85

if [ $# -ne 3 ]  # Correct number of arguments passed to script?
then
  echo "Usage: `basename $0` nom_app taille_vm nb_vm"
  exit $ERR_ARGS
fi

case $1 in
    chat|FTP) 
	echo "Application : $1";;
    *)
	echo "Usage chat | FTP : $1";
	exit $ERR_ARGS;;
esac

case $2 in
    xs|tiny|small|medium|large|xlarge)
        echo "Flavor : $2";;
    *)
	echo "Usage: xs | tiny | small | medium | large | xlarge : $2";
	exit $ERR_ARGS;;
esac

if [ $3 -gt 10 ]
then
	echo "Usage : nombre de vm < 10 : $3";
	exit $ERR_ARGS;
fi

if ! [ -d ../../Serveur/ ]; then
	#/!\ les applications sont presentes dans frontend/xp5k-openstack/Serveur
	echo 'Nothing to deploy.. There is no Serveur/ in xp5k-openstack directory !';
fi

echo '#+------------------------+';
echo '#|       VM_LAUNCHER      |';
echo '#+------------------------+';

for i in `seq 1 $3`;
do
	rake cmd cmd="echo '#### START_RAKE ####';
	source openstack-openrc.sh;

	echo '#### CREATION VM1 ####';
	nova boot --flavor m1.$2 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo default$i;

	echo '#### AJOUTE IP PUBLIQUE ####';
	IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
	\`sleep 2\`;
	nova add-floating-ip default$i \$IP_PUB;
	echo \$IP_PUB;

	echo '#### MODIFIE DROITS ####';
	VAR_RULE=\`(nova secgroup-list-rules default | grep -o 10000)\`;

	if [ -z \$VAR_RULE ]
	then
		nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
	fi
	 " host=controller;

done

#On fetch l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "*Adresse du controller* > $ADR";

#On s'y connecte pour fetch la liste des IP_VM
IPs=`ssh root@$ADR 'source openstack-openrc.sh && nova floating-ip-list' | cut -d '|' -f 3 | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'`;
echo "#### IP VMs > $IPs ####";

for IP in $IPs; do
echo "#### VM : $IP ####";

scp -p -r ../../Serveur/ debian@$IP: ;
ssh debian@$IP "sudo apt-get -y update; sudo apt-get -y install gcc make; cd Serveur/$1/; make;";

echo '#### Apps installees ####';
done

