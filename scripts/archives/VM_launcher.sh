#̣! /bin/bash

#$>frontend
ERR_ARGS=85

if [ $# -ne 2 ]  # Correct number of arguments passed to script?
then
  echo "Usage: `basename $0` vm_name vm_size"
  exit $ERR_ARGS
fi

case $2 in
    xs | tiny | small | medium | large | xlarge )
        echo "Flavor : $2";;
    * )
	echo "Usage: xs | tiny | small | medium | large | xlarge : $2";
	exit $ERR_ARGS;;
esac


echo '#+------------------------+';
echo '#|       VM_LAUNCHER      |';
echo '#+------------------------+';

rake cmd cmd="echo '#### START_RAKE ####';
source openstack-openrc.sh;

echo '#### CREATION VM1 ####';
nova boot --flavor m1.$2 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo $1;


echo '#### AJOUTE IP PUBLIQUE ####';
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
nova add-floating-ip $1 \$IP_PUB;
echo \$IP_PUB;

echo '#### MODIFIE DROITS ####';
VAR_RULE=\`(nova secgroup-list-rules default | grep -o 10000)\`;

if [ \$VAR_RULE -ne 10000 ]
then
	nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
fi
 " host=controller;


#./APP_installer.sh;

