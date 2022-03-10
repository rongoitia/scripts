#!/usr/bin/python3.6
import pyhdb
import json
import sys
from collections import Counter


port = 30015
host = sys.argv[1]
user = sys.argv[2]
password = sys.argv[3]


class QueryExecutor:

    def __init__(self, host, port, user, password):
        self.host = host
        self.port = port
        self.user = user
        self.password = password

    def cursor_instance(self):
        connection = pyhdb.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password
            )
        cursor = connection.cursor()
        return cursor

    def Exec(self, query):
        cursor = self.cursor_instance()
        cursor.execute(query)
        l = cursor.fetchall()
        return l

class query_processor:

    def switcher(self, q_type, value):
        method = getattr(self, q_type)
        return method(value)

    def users(self, value):
        number = Counter(value).keys()
        number = len(number)
        return number

    def general(self, value):
        value = str(value[0][0])
        return value
    
    def query_builder(self, q_type, v_type, m_type):

        if m_type == 'percentage':
            m_type = 'used_size*100/total_size'

        memory = ' select ' + m_type + ' from _SYS_STATISTICS.HOST_SERVICE_MEMORY where SERVICE_NAME = ' + v_type +' ORDER BY SERVER_TIMESTAMP DESC LIMIT 1'
        disks = 'select ' + m_type + ' from M_DISKS where path = ' + v_type
        schemas = 'select ROUND(SUM(' + m_type +')) from M_CS_TABLES where SCHEMA_NAME = '+ v_type +' GROUP BY SCHEMA_NAME'

        query_dict = {
            '--memory' : memory,
            '--disks' : disks,
            '--schemas' : schemas
        }
        query = query_dict[q_type]
        return query 


class lld_json_builder:

    def disks_lld(self, data):
            
        lld_list = list()
        for path in data:

            dictx = {'{#ITEMNAME}': path[0], '{#ITEMUNIT}': 'used_size'}
            lld_list.append(dictx)
            dictx = {'{#ITEMNAME}': path[0], '{#ITEMUNIT}': 'total_size'}
            lld_list.append(dictx)
            dictx = {'{#ITEMNAME}': path[0], '{#ITEMUNIT}': 'percentage'}
            lld_list.append(dictx)

        
        lld_final = {'data': lld_list}
        return json.dumps(lld_final, indent=3, sort_keys=True)

    def schema_lld(self, data):

        lld_list = list()
        for schema in data:

            dictx = {'{#ITEMNAME}': schema[0], '{#ITEMUNIT}': 'MEMORY_SIZE_IN_TOTAL'}
            lld_list.append(dictx)

        lld_final = {'data': lld_list}
        return json.dumps(lld_final, indent=3, sort_keys=True)
        
       
query_map = {    
        #numero de usuarios
        "users" : 
            {
                "query" : "SELECT user_name FROM M_CONNECTIONS where connection_status != '';",
                "name" : "Number of connected users",
                "unit" : "users"
            },
       "blocked_users" :
            {
                "query" : ''' Select user_name from "SYS"."USERS" WHERE USER_DEACTIVATED='TRUE' ''',
                "name" : "Number of blocked users",
                "unit" : "users"
            },
        "lld" :
            {
                "query" : "select path from M_DISKS",
                "name" : "Disk paths to assemble lld json",
                "unit" : "paths"
            },
         "lld_schemas" :
            {
                "query" : "select SCHEMA_NAME from M_CS_TABLES GROUP BY SCHEMA_NAME ORDER BY SCHEMA_NAME ASC",
                "name" : "Schemas in hanadb",
                "unit" : "schemas"
            }
        
        }

def main():

    query = QueryExecutor(host, port, user, password)
    if sys.argv[4] == '--disks':
        if sys.argv[5] == 'lld':
            data = query.Exec(query_map["lld"]["query"])
            output =  lld_json_builder().disks_lld(data)
            print(output) 
        else:
            path = "'" + sys.argv[5] + "'"
            m_type = sys.argv[6]
            querystr = query_processor().query_builder(sys.argv[4], path, m_type)
            data = query.Exec(querystr)
            value = query_processor().switcher('general', data)
            print(value)
    elif sys.argv[4] == '--users':
        query_id = sys.argv[5]
        querysrt = query_map[query_id]["query"]
        data = query.Exec(querysrt)
        value = query_processor().switcher('users', data)
        print(value)
        
    elif sys.argv[4] == '--memory':
        service = "'" + sys.argv[5] + "'"
        m_type = sys.argv[6]
        querystr = query_processor().query_builder(sys.argv[4], service, m_type)
        data = query.Exec(querystr)
        value = query_processor().switcher('general', data)
        print(value)
    
    elif sys.argv[4] == '--schemas':
        if sys.argv[5] == 'lld':
            data = query.Exec(query_map["lld_schemas"]["query"])
            output =  lld_json_builder().schema_lld(data)
            print(output) 
        else:
            schema = "'" + sys.argv[5] + "'"
            m_type = sys.argv[6]
            querystr = query_processor().query_builder(sys.argv[4], schema, m_type)
            data = query.Exec(querystr)
            value = query_processor().switcher('general', data)
            print(value)            


    else:
        pass
       
if __name__ == '__main__':
    main()
