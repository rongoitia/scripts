#!/bin/bash
dshost='10.0.201.162:4119'
alertid=$1
targetid=$2
sid='sid'
path='/usr/share/zabbix/externalscripts/deep_security'
date=$(date "+%d-%m-%Y %H:%M:%S")

#Se le hace dismiss a la alerta según los ids
curl -s --location -g --request DELETE 'https://'$dshost'/rest/alerts/'$alertid'/target/'$targetid'' --header 'Cookie: sID='$sid';' --insecure


