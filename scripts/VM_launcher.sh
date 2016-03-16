#̣! /bin/bash

#TODO: Vérifier que les droits n'ont pas déjà été modifiés

#$>frontend
ERR_ARGS=85

if [ $# -ne 1 ]  # Correct number of arguments passed to script?
then
  echo "Usage: `basename $0` vm_name"
  exit $ERR_ARGS
fi

echo '#+------------------------+';
echo '#|			VM_LAUNCHER				|';
echo '#+------------------------+';

rake cmd cmd="echo '#+------------------------+';
echo '#|			START_RAKE				|';
echo '#+------------------------+';
source openstack-openrc.sh;


echo '#+------------------------+';
echo '#|			CREATION VM1			|';
echo '#+------------------------+';

nova boot --flavor m1.xs --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo $1;


echo '#+------------------------+';
echo '#|	AJOUTE IP PUBLIQUE		|'; 
echo '#+------------------------+';
 
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
nova add-floating-ip $1 \$IP_PUB;
echo \$IP_PUB;

echo '#+------------------------+';
echo '#|			MODIFIE DROITS		|';
echo '#+------------------------+';

VAR_RULE=\`(nova secgroup-list-rules default | grep -o 10000)\`;

if [ \$VAR_RULE -ne 10000 ]
then
	nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
fi
 " host=controller;


#./APP_installer.sh;

