#̣! /bin/bash
#$>frontend
echo '#+--------------------------+';
echo '#|	Copie des applications	|';
echo '#+--------------------------+';

#On fetch l'adresse du controller
ADR=`rake roles:show | grep -o -E '[a-z0-9-]+\.[a-z]+\.grid5000\.fr'`;
echo "*Adresse du controller* > $ADR";

#On s'y connecte pour fetch la liste des IP_VM
IPs=`ssh root@$ADR 'source openstack-openrc.sh && nova floating-ip-list' | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'`;
echo "*IP VMs* > $IPs";

#TODO: Transcrire en de multiples IP :
: '
for TOKEN in strtok($IPs, '\n'); do 

scp -p -r ../Serveur debian@$TOKEN: ; #/!\ les applications sont présentes sur le frontend
ssh debian@$TOKEN "sudo apt-get update; sudo apt-get gcc; cd Serveur; make;";

echo "Apps installees";

done
'
