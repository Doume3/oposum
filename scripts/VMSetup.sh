#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 2 ]; then
  echo "Usage: `basename $0` taille_VM nom_VM"
  exit $ERR_ARGS
fi

echo "- Vérification de la taille de la VM ($1)";
case $1 in
    xs|small|medium|large|xlarge)
        ;;
    *)
        echo "taille_VM: xs | tiny | small | medium | large | xlarge : $1";
        exit $ERR_ARGS;;
esac

mkdir -p logs/$2/
LOG="logs/$2/VMSetup.log"

# On récupère l'adresse du controller
ADR=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "# Controleur: $ADR" >> $LOG

echo "- Vérification de la keypair";
KEYPAIR=`ssh root@$ADR 'source openstack-openrc.sh && nova keypair-list' | grep -o -E 'mainKey'`;
if [ -z $KEYPAIR ]; then
        cat ~/.ssh/id_rsa.pub | ssh root@$ADR "source openstack-openrc.sh && nova keypair-add --pub_key - mainKey"
fi

NOMSVMS=`ssh root@$ADR 'source openstack-openrc.sh && nova list' | cut -d '|' -f 3 | grep -o -E '(nvm_.+)'`;

echo "- Vérification du nom de la VM ($2)";
for NOMVM in $NOMSVMS; do
        if [ "$NOMVM" = "nvm_$2" ]; then
                echo "Le nom de la VM $2 existe déjà, veuillez en choisir un autre"
                exit $ERR_ARGS
        fi
done

echo "- Création de la VM...";
rake cmd cmd="
echo '# Execution du source openstack';
source openstack-openrc.sh;

VAR_RULE=\`nova secgroup-list-rules default | grep -o 10000\`;
if [ -z \"\$VAR_RULE\" ]; then
        echo '# Ajout des règles du parfeu'
        nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;
        nova secgroup-add-rule default udp 10000 10100 0.0.0.0/0;
fi

echo '# Création de la VM';
nova boot --flavor m1.$1 --image 'Debian Jessie 64-bit' --nic net-id=\$(neutron net-show -c id -f value private) --key_name mainKey $2

echo '# On attend que la VM soit disponible';
while [ -z \"\`nova list --name nvm_$2 | cut -d '|' -f 4 | grep -o -E '(ACTIVE)'\`\" ]; do
        sleep 2;
done

echo '# Création de l IP publique';
IP_PUB=\`nova floating-ip-create public | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
echo \"# Ajout de l'IP publique (\$IP_PUB) à la VM\";
nova add-floating-ip nvm_$2 \$IP_PUB;
" host=controller >> $LOG

echo "- VM créée";

# Connexion au controleur pour récupèrer l'IP de la VM
IP=`ssh root@$ADR "source openstack-openrc.sh && nova list --name nvm_$2" | cut -d '|' -f 7 | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'`;

echo "- En attente de connexion ssh disponible ($IP)";
while ! ssh -q debian@$IP 'exit'; do
        sleep 2;
done

echo "- Mise à jour de la VM...";
ssh -q debian@$IP "echo '# UPDATE'; sudo apt-get -y update; echo '# UPGRADE'; sudo apt-get -y upgrade; echo '# INSTALL'; sudo apt-get -y install g++ gcc make;" >> $LOG
echo "- Mise à jour réussie";

exit 0
