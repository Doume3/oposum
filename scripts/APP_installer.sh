#̣! /bin/bash
#$>frontend
echo '#+--------------------------+';
echo '#|	Copie des applications	|';
echo '#+--------------------------+';

#On fetch l'adresse du controller
ADR=`rake roles:show | grep "controller" | grep -o -E "[^: ]*\.grid5000\.fr"`;
echo "*Adresse du controller* > $ADR";

#On s'y connecte pour fetch la liste des IP_VM
IPs=`ssh root@$ADR 'source openstack-openrc.sh && nova floating-ip-list' | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'`;
echo "*IP VMs* > $IPs";

for IP in $IPs; do 
echo "VM : $IP";

scp -p -r ../Serveur debian@$IP: ; #/!\ les applications sont présentes sur le frontend
ssh debian@$IP "sudo apt-get update; sudo apt-get install gcc; cd Serveur; make";

echo "Apps installees";

done
