#!/bin/bash

nova floating-ip-list | egrep -e "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\ " | cut -d '|' -f 3 | cut -c 2-
