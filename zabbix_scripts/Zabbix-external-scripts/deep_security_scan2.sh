#!/bin/bash

dshost='10.0.201.162:4119'
path='/usr/share/zabbix/externalscripts/deep_security'
sid='sid'
apikey='apikey'

#Si no se le pasa parametro se ejecuta la discovery rule en formato Zabbix
if [ "$1" == "" ]
then
#Se hace el descubrimiento de todas las alertas para extraer su id 
alertid=$(curl -s --location --request GET 'https://'$dshost'/rest/alerts' \
 --header 'Cookie: sID='$sid';' \
 --insecure | jq '.ListAlertsResponse.alerts[] | "\(.id) \(.name)"' \
 | grep "TCP Null Scan" | sed 's/"//g'| awk -F " " '{print $1}')
	
#Se hace la búsqueda de las alertas por la legacy API y se extraen los ids de los hosts en un hostids.txt
curl -s --location --request GET 'https://'$dshost'/rest/alerts?alertID='$alertid'&op=eq' \
--header 'Cookie: sID='$sid';' \
--insecure | jq .ListAlertsResponse.alerts[].targets[].urn | awk -F "/" '{print $2}'| sed 's/"//' > $path/hostids2.txt

#Se extraen el tiempo en que fueron levantadas las alertas y sus ids en timeraised_ids.txt
 curl -s --location --request GET 'https://'$dshost'/rest/alerts?alertID='$alertid'&op=eq' \
 --header 'Cookie: sID='$sid';' \
 --insecure | jq '.ListAlertsResponse.alerts[].targets[] | "\(.id) \(.timeRaised)"' | sed 's/"//g' | sed 's/ /,/g' > $path/timeraised2_ids.txt

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
done < $path/hostids2.txt > $path/scanned_hosts2.txt

#Se combinan los resultados en una misma file (scanned_hosts_final.csv)
paste --delimiter=',' $path/scanned_hosts2.txt $path/timeraised2_ids.txt > $path/scanned_hosts_final2.csv

#Se convierte todo al formato de json aceptado por Zabbix y se imprime
todo=$(while read line; do
    host=$(echo $line | awk '{ print $1 }' FS=",")
    id=$(echo $line | awk '{ print $2 }' FS=",")
    timeraised=$(echo $line | awk '{ print $3 }' FS=",")
    JSONZABBIX=$(echo '{ "{#HOST}":'$host', "{#ALERTID}":"'$alertid'", "{#TARGETID}":"'$id'", "{#TIMERAISED}":"'$timeraised'" },')
    echo $JSONZABBIX
  done < $path/scanned_hosts_final2.csv)
contenido=$(echo $todo | sed 's/.$//')
echo '{"data":['$contenido']}' | jq

#Si se le pasa el hostname como parametro imprime la fecha en la que fue levantada la alarma
else
 grep "$1" $path/scanned_hosts_final2.csv | awk -F "," '{print $3}'
 exit
fi

