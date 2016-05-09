#!/bin/bash

echo -e "\n\e[1;41m   Suppression des log   \e[0m";
rm -r -f logs/*;

echo -e "\n\e[1;41m   Suppression des VM   \e[0m";
rake cmd cmd="source openstack-openrc.sh;
VMVAR=\`nova list | cut -d '|' -f 3 | cut -c 2- | grep -v -E 'Name|--+'\`;
for VM in \$VMVAR;do
nova delete \$VM;
done;
\`sleep 2\`;
IPPUB=\`nova floating-ip-list | cut -d '|' -f 3 | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
for IP in \$IPPUB; do
nova floating-ip-delete \$IP;
done" host=controller > /dev/null;
