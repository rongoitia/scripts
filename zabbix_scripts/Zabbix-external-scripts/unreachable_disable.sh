#!/bin/bash

ip="10.10.30.173"
user=$1  
passwd=$2
path='./disabled-hosts'
mkdir -p disabled-hosts

#Token de autenticación
export token=$(curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "user.login",
    "params": {
        "user": "'"$user"'",
        "password": "'"$passwd"'"
    },
    "id": 1
}'| cut -d : -f3 | cut -d , -f1)

#Se hace request de los hostid de los unreachables por agente
curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": ["hostid"],
        "filter": {
            "available": 2
        }
    },
    "auth": '"$token"',
    "id": 1
}' | jq '.result[].hostid' | sed 's/"//g' > $path/agent.txt 


#Se deshabilitan los hosts por agente (cambiar el status a 0 si se desea revertir)
while read line; do
curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
  {
    "jsonrpc": "2.0",
    "method": "host.update",
    "params": {
        "hostid": '"$line"',
        "status": 1
    },
    "auth": '"$token"',
    "id": 1
}' > /dev/null
echo "Host '$line' deshabilitado"
done < $path/agent.txt 

#Se hace request de los hostid de los unreachables por snmp
 curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": ["hostid"],
        "filter": { 
            "snmp_available": 2
        }
    },
    "auth": '"$token"',
    "id": 1
}' | jq '.result[].hostid' | sed 's/"//g' > $path/snmp.txt 


#Se deshabilitan los hosts por snmp (cambiar el status a 0 si se desea revertir)
while read line; do
curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
  {
    "jsonrpc": "2.0",
    "method": "host.update",
    "params": {
        "hostid": '"$line"',
        "status": 1  
    },
    "auth": '"$token"',
    "id": 1
}' > /dev/null
echo "Host '$line' deshabilitado"
done < $path/snmp.txt 

