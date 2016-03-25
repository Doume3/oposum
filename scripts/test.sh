#!/bin/bash

ADRESSE=`rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`;
echo "*Adresse du controller* > $ADRESSE";
KEYPAIR=`ssh root@$ADRESSE 'source openstack-openrc.sh && nova keypair-show demo' | grep -o -E 'demo'`;
echo "*Keypair* > $KEYPAIR";
if [ -z $KEYPAIR ]; then
        echo 'coucou';
fi

#On s'y connecte pour fetch la liste des IP_VM
IPs=`ssh root@$ADRESSE 'source openstack-openrc.sh && nova floating-ip-list' | cut -d '|' -f 3 | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'`;
echo "*IP VMs* > $IPs";

for IP in $IPs; do
echo "VM : $IP";

scp -p -r ../Serveur/ debian@$IP: ; #/!\ les applications sont présentes sur le frontend
ssh debian@$IP "sudo apt-get -y update; sudo apt-get -y install gcc make; cd Serveur/chat/; make;"; # Serveur/chat ou Serveur/FTP

echo 'Apps installees';

done

