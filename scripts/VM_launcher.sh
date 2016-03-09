#̣! /bin/bash
#le fichier à copier dans chaque machine virtuelle est déjà présent ds le frontend
rake cmd cmd="source openstack-openrc.sh;
	      nova keypair-add --pub_key - demo;
	      nova boot --flavor m1.xs --image "Debian Jessie 64-bit" --nic net-id=$(neutron net-show -c id -f value private) --key_name demo $1;
	      nova boot --flavor m1.xs --image "Debian Jessie 64-bit" --nic net-id=$(neutron net-show -c id -f value private) --key_name demo $2;
	      nova floating-ip-create public | MAVAR1=`./ipfloat.sh`;
              nova add-floating-ip $1 $MAVAR1;
	      nova floating-ip-create public | MAVAR2=`./ipfloat.sh`;
              nova add-floating-ip $2 $MAVAR2;
	      nova secgroup-add-rule default tcp 10000 10100 0.0.0.0/0;" host=controller;
scp -p -r Serveur debian@$MAVAR1: ;
scp -p -r Serveur debian@$MAVAR2: ;
ssh debian@$MAVAR1 "sudo apt-get update; sudo apt-get gcc; cd Serveur; Make;";
ssh debian@$MAVAR2 "sudo apt-get update; sudo apt-get gcc; cd Serveur; Make;";

