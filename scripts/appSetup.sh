#!/bin/bash

ERR_ARGS=-1

if [ $# -ne 5 ]
then
  echo "Usage: `basename $0` nom_vm nom_app type_app port_app path_app"
  exit $ERR_ARGS
fi

case $3 in
    client|serveur) 
	echo "type_app : $1";;
    *)
	echo "Usage: client | serveur";
	exit $ERR_ARGS;;
esac

if [ $4 -lt 10000 ] && [ $4 -gt 10100 ] then
    echo "port_app : $4";
	echo "Usage: 10000 <= type_app <= 10100";
	exit $ERR_ARGS;
fi

if [ -d "$5" ] then
	echo "path_app : $5";
	echo "Usage : my/path/my/rep/";
	exit $ERR_ARGS;
fi

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

