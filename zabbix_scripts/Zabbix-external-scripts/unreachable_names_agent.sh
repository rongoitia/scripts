#!/bin/bash

ip="10.10.30.173"
user=$1
passwd=$2
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

#Se hace request de los nombres de hosts unreachable por agente

curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": ["available","host"],
        "filter": {
            "available": 2
        }
    },
    "auth": '"$token"',
    "id": 1
}'

