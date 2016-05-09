#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 2 ]; then
  echo "Usage: `basename $0` taille_VM nom_VM"
  exit $ERR_ARGS
fi

echo -e "\n\e[1;44m   Vérification de la taille de la VM ($1)   \e[0m";
case $1 in
    xs|small|medium|large|xlarge)
        ;;
    *)
        echo "taille_VM: xs | small | medium | large | xlarge : $1";
        exit $ERR_ARGS;;
esac

mkdir -p logs/$2/
LOG="logs/$2/VMSetup.log"

# On récupère l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "# Controleur: $ADR" >> $LOG

echo -e "\n\e[1;44m   Vérification de la Key Pair   \e[0m";
KEYPAIR=`ssh root@$ADR 'source openstack-openrc.sh && nova keypair-list' | grep -o -E 'mainKey'`;
if [ -z $KEYPAIR ]; then
        echo -e "\e[1;42m   Ajout de la Key Pair   \e[0m";
        cat ~/.ssh/id_rsa.pub | ssh root@$ADR "source openstack-openrc.sh && nova keypair-add --pub_key - mainKey"
fi

NOMSVMS=`ssh root@$ADR 'source openstack-openrc.sh && nova list' | cut -d '|' -f 3 | grep -o -E '([a-zA-Z0-9_]+)' | grep -v 'Name'`;

echo -e "\n\e[1;44m   Vérification du nom de la VM ($2)   \e[0m";
if ! [[ "$2" =~ ^[a-zA-Z0-9_]+$ ]]; then
	echo "Le nom de la VM doit être alphanumerique (a-zA-Z0-9_)"
	exit $ERR_ARGS
fi
for NOMVM in $NOMSVMS; do
	if [ "$NOMVM" = "$2" ]; then
	    echo "Le nom de la VM $2 existe déjà, veuillez en choisir un autre"
	    exit $ERR_ARGS
	fi
done

echo -e "\n\e[1;44m   Création de la VM   \e[0m";
rake cmd cmd="
echo '# Execution du source openstack';
source openstack-openrc.sh;

VAR_RULE=\`nova secgroup-list-rules default | grep -o 10000\`;
if [ -z \"\$VAR_RULE\" ]; then
        echo '# Ajout des regles du parfeu'
        nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
        nova secgroup-add-rule default udp 10000 10100 0.0.0.0/0;
fi

echo '# Creation de la VM';
nova boot --flavor m1.$1 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name mainKey $2

echo '# On attend que la VM soit disponible';
while [ \"\`nova list --name $2 | grep -o -E 'ACTIVE|ERROR'\`\" != 'ACTIVE' ]; do
	if [ \"\`nova list --name $2 | grep -o -E 'ACTIVE|ERROR'\`\" = 'ERROR' ]; then
		nova delete $2;
		nova boot --flavor m1.$1 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name mainKey $2
	fi
        sleep 2;
done

echo '# Creation de l IP publique';
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
echo \"# Ajout de l IP publique (\$IP_PUB) a la VM\";
nova add-floating-ip $2 \$IP_PUB;
" host=controller >> $LOG

echo -e "\e[1;42m   VM créée   \e[0m";

# Connexion au controleur pour récupèrer l'IP de la VM
IP=`ssh root@$ADR "source openstack-openrc.sh && nova list --name $2" | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;

echo -e "\n\e[1;44m   En attente de connexion SSH disponible ($IP)   \e[0m";
while ! ssh -q debian@$IP 'exit'; do
	sleep 2;
done

echo -e "\n\e[1;44m   Mise à jour de la VM   \e[0m";
ssh -q debian@$IP "sudo apt-get -yq update; export TERM=linux; sudo apt-get -yq install gcc make > /dev/null 2>&1;" >> $LOG;
echo -e "\e[1;42m   Mise à jour réussie   \e[0m\n";

exit 0
