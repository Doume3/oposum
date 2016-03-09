#!/bin/bash

ssh root@edel-27.grenoble.grid5000.fr 'source openstack-openrc.sh;./ipfloat.sh' > ipfloat.txt
read nomscript
ssh debian@10.132.4.11 bash < $nomscript
ssh debian@10.132.4.12 bash < $nomscript
