#̣! /bin/bash
#le fichier à copier dans chaque machine virtuelle est déjà présent ds le frontend
#probleme avec la recuperation des IP depuis le controller jusqua frontend

if [ $# -eq 2 ]; then
echo "__SCRIPT_START__";
IP1=;
IP2=;
rake cmd cmd="echo '#+----------------------------------+';
echo '#|	__RAKE_START__   	  |';
echo '#+----------------------------------+';
	      source openstack-openrc.sh;

echo '#+----------------------------------+';
echo '#|	CREATION VM1	  	  |';
echo '#+----------------------------------+';

	      nova boot --flavor m1.xs --image \"Debian Jessie 64-bit\" --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo $1;

echo '#+----------------------------------+';
echo '#|	CREATION VM2	  	  |';
echo '#+----------------------------------+';

	      nova boot --flavor m1.xs --image \"Debian Jessie 64-bit\" --nic net-id=\$(neutron net-show -c id -f value private) --key_name demo $2;

echo '#+----------------------------------+';
echo '#|	AJOUTE IP PUBLIC  vm1 	  |';
echo '#+----------------------------------+';

	      MAVAR1=\`nova floating-ip-create public | egrep -e \"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\ \" | cut -d '|' -f 3 | cut -c 2-\`;
              nova add-floating-ip $1 \$MAVAR1;
	      IP1=\$MAVAR1;
echo '#+----------------------------------+';
echo '#|	AJOUTE IP PUBLIC  vm2 	  |';
echo '#+----------------------------------+';

	      MAVAR2=\`nova floating-ip-create public | egrep -e \"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\ \" | cut -d '|' -f 3 | cut -c 2-\`;
              nova add-floating-ip $2 \$MAVAR2;
	      IP2=\$MAVAR2;
echo '#+----------------------------------+';
echo '#|	MODIFIE DROITS   	  |';
echo '#+----------------------------------+';

	      nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;" host=controller;

echo '#+----------------------------------+';
echo '#|	Copie des applications 	  |';
echo '#+----------------------------------+';
#SOLUTION : piper un ssh dans le controller

echo "**** IP VM : $IP1 , $IP2";
scp -p -r ../Serveur debian@$IP1: ;
scp -p -r ../Serveur debian@$IP2: ;
ssh debian@$IP1 "sudo apt-get update; sudo apt-get gcc; cd Serveur; make;";
ssh debian@$IP2 "sudo apt-get update; sudo apt-get gcc; cd Serveur; make;";
echo "Apps installes";

else 

echo 'Mauvais nombre dargs';

fi
