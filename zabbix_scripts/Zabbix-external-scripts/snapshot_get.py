#!/usr/bin/python3.6
import ssl
from pyVim.connect import SmartConnect
from pyVmomi import vim
import json
import sys
import urllib3
import time
import datetime
import pickle 


tmpfile = '/var/lib/zabbixs/tmp/snapshot1.pickle'
host= "vicvcenter00.ar.company.local"
user= "user\zabbix_service" 
pwd= "password"


def get_snapshotdate(snapshot_id):
    
    filename = tmpfile
    with open(filename, 'rb') as f:
        data = pickle.load(f)

    return data[snapshot_id]
    

def recursive_tree_traverse(obj1, niveles, lld_list, data_dict, vm_name):

    for x in obj1.childSnapshotList:       
        try:
            #obteniendo datos para lld
            nivstr = str(niveles)
            snapshot_name = str(x.snapshot)
            snapshot_id = str(x.id)
            snapshot_vm = str(x.vm)
            dictx = {'{#ITEMNAME}': snapshot_name, '{#ITEMKEY}': snapshot_id, '{#VMNAME}': vm_name, '{#VMID}': snapshot_vm}
            lld_list.append(dictx)
            #obteniendo datos de timepo
            creation_date = str(x.createTime)
            creation_date = creation_date[:19]
            creation_timeobj = datetime.datetime.strptime(creation_date, '%Y-%m-%d %H:%M:%S')
            now_timestamp = datetime.datetime.now().timestamp()
            creation_timestamp = creation_timeobj.timestamp()
            duration = int(now_timestamp) - int(creation_timestamp)
            duration = duration/60   #segundos entre 60
            duration_hours = duration/60   #minutros entre 60
            #guardando duracion en diccionario
            data_dict[str(x.id)] = (str(int(duration_hours)))
            if not x.childSnapshotList:
                pass
            else:
                niveles = niveles + 1
                nivstr = str(niveles)
                #print("NIVEL:" + nivstr)
                recursive_tree_traverse(x, niveles, lld_list, data_dict, vm_name)
        except:
            pass


def lld():

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning) #deshabilitar la advertencia
    s=ssl.SSLContext(ssl.PROTOCOL_TLSv1)
    s.verify_mode=ssl.CERT_NONE
    si= SmartConnect(host=host, user=user, pwd=pwd,sslContext=s)
    content=si.content
    # Method that populates objects of type vimtype
    def get_all_objs(content, vimtype):
        obj = {}
        container = content.viewManager.CreateContainerView(content.rootFolder, vimtype, True)
        for managed_object_ref in container.view:
                obj.update({managed_object_ref: managed_object_ref.name})
        return obj

    getAllVms=get_all_objs(content, [vim.VirtualMachine])

    lld_list = list()
    data_dict = dict()
    for vm in getAllVms:
        try:
            rootlist = vm.snapshot.rootSnapshotList

            for x in rootlist:
                #print('PRIMER ROOT')
                recursive_tree_traverse(x, 0, lld_list, data_dict, vm.name)
        except:
            pass

    lld_final = {'data': lld_list}
    print(json.dumps(lld_final, indent=3, sort_keys=True))
    filename = tmpfile

    with open(filename, 'wb') as f:
            pickle.dump(data_dict, f)


def main():

    if sys.argv[1] == '-l':
        lld()
    elif sys.argv[1] == '-g':
        snapshot_id = sys.argv[2]
        p = get_snapshotdate(snapshot_id)
        print(p)

    else:
        pass
       
if __name__ == '__main__':
    main()


    #948
