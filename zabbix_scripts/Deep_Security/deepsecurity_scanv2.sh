#!/bin/bash

dshost='10.0.201.162:4119'
path='/home/nubiral02/Documents/Zabbix/zbbx-shell-scripts/deep_security'
sid='D1944AA1F09628760B840E9D10692268'
apikey='E1091CB5-0146-8EB8-7A8C-ADAB66C3C3A7:77iXmVNNAptMvrDpFkj/NjyCGut6e8f0LE5/4DoYBPc='

#Si el parametro está vacío se ejecuta el discovery
if [ "$1" == "" ]
then
 # Se hace el descubrimiento de todas las alertas para extraer su id 
 alertid=$(curl -s --location --request GET 'https://'$dshost'/rest/alerts' \
 --header 'Cookie: sID='$sid';' \
 --insecure | jq '.ListAlertsResponse.alerts[] | "\(.id) \(.name)"' \
 | grep "Network or Port Scan" | sed 's/"//g'| awk -F " " '{print $1}')
 
 #Se hace la búsqueda de las alertas por la legacy API y se extraen los ids de los hosts en un hostids.txt
 curl -s --location --request GET 'https://'$dshost'/rest/alerts?alertID='$alertid'&op=eq' \
 --header 'Cookie: sID='$sid';' \
 --insecure | jq .ListAlertsResponse.alerts[].targets[].urn | awk -F "/" '{print $2}'| sed 's/"//' > $path/hostids.txt

 #Se extraen el tiempo en que fueron levantadas las alertas y sus ids en timeraised_ids.txt
 curl -s --location --request GET 'https://'$dshost'/rest/alerts?alertID='$alertid'&op=eq' \
 --header 'Cookie: sID='$sid';' \
 --insecure | jq '.ListAlertsResponse.alerts[].targets[] | "\(.id) \(.timeRaised)"' | sed 's/"//g' | sed 's/ /,/g' > $path/timeraised_ids.txt

 #Se buscan los hostnames según sus ids
 while read line;do
 curl -s --location --request POST 'https://'$dshost'/api/computers/search?expand=none' \
 --header 'api-secret-key: '$apikey'' \
 --header 'api-version: v1' \
 --header 'Content-Type: application/json' \
 --data-raw '{
  "searchCriteria": [
    {
      "idValue": '$line'
    }
  ],
  "sortByObjectID": true
 }' --insecure | jq '.computers[] | "\(.hostName) \(.lastIPUsed)"';
 done < $path/hostids.txt > $path/scanned_hosts.txt

 #Se combinan los resultados en una misma file (scanned_hosts_final.csv)
 paste --delimiter=',' $path/scanned_hosts.txt $path/timeraised_ids.txt > $path/scanned_hosts_final.csv

 #Se convierte todo al formato de json aceptado por Zabbix
 todo=$(while read line; do
    host=$(echo $line | awk '{ print $1 }' FS=",")
    id=$(echo $line | awk '{ print $2 }' FS=",")
    timeraised=$(echo $line | awk '{ print $3 }' FS=",")
    JSONZABBIX=$(echo '{ "{#HOST}":'$host', "{#ALERTID}":"'$alertid'", "{#TARGETID}":"'$id'", "{#TIMERAISED}":"'$timeraised'" },')
    echo $JSONZABBIX
  done < $path/scanned_hosts_final.csv) 
 contenido=$(echo $todo | sed 's/.$//')
 echo '{"data":['$contenido']}' | jq

 #Si se le pasa como parametro el nombre del host imprime solo la fecha en que fue levantada la alarma (item prototypes)
else
 grep "$1" $path/scanned_hosts_final.csv | awk -F "," '{print $2}'
exit 0
fi

