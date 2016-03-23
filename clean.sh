#!/bin/bash


echo "+------------------+";
echo "|  Destruction VM  |";
echo "+------------------+";

rake cmd cmd="source openstack-openrc.sh;

VMVAR=\`nova list | cut -d '|' -f 2 | cut -c 2- | grep -E '([a-z0-9]+-){4}[a-z0-9]+'\`;
for VM in \$VMVAR;do
nova delete \$VM;
done" host=controller;

rake cmd cmd="source openstack-openrc.sh;

IPPUB=\`nova floating-ip-list | cut -d '|' -f 3 | grep -o -E '(([0-9]{1,3}\.){3}[0-9]{1,3})'\`;
for IP in \$IPPUB; do
nova floating-ip-delete \$IP;
done" host=controller;
