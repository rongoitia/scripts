#!/bin/bash
dshost='10.0.201.162:4119'
alertid=$1
targetid=$2
sid='D1944AA1F09628760B840E9D10692268'
path='/usr/share/zabbix/externalscripts/deep_security'
date=$(date "+%d-%m-%Y %H:%M:%S")

#Se le hace dismiss a la alerta según los ids
curl -s --location -g --request DELETE 'https://'$dshost'/rest/alerts/'$alertid'/target/'$targetid'' --header 'Cookie: sID='$sid';' --insecure

#Troubleshooting logs
output=$(echo $?)
if [ $output -eq 0 ];then
 echo "$date - el comando fue exitoso: $output, id alerta: $alertid" >> $path/test_dismiss.log
else
 echo "$date - el comando fue erroneo: $output, id alerta: $alertid" >> $path/test_dismiss.log
fi
exit
