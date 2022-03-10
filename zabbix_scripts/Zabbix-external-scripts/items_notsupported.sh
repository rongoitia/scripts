#!/bin/bash

ip="10.10.30.173"
user=$1
passwd=$2
export token=`curl -s -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "user.login",
    "params": {
        "user": "'$user'",
        "password": "'$passwd'"
    },
    "id": 1
}'| cut -d : -f3 | cut -d , -f1`

#Se hace request de número de items not supported
 
curl -H "Content-type: application/json-rpc" -X POST http://$ip/zabbix/api_jsonrpc.php -d'
{
    "jsonrpc": "2.0",
    "method": "item.get",
    "params": {
        "countOutput": true,
        "monitored": true,
        "filter": {
            "state": 1
        }
    },
    "auth": '$token',
    "id": 1
}'


