import json
import os.path
from os import listdir
from os.path import isfile, join
from elasticsearch import Elasticsearch

elasticIP = "192.168.35.133"
elasticPort = "9200"
correct_paths = 0
while correct_paths != 1:
    print "Elastic IP " + elasticIP
    print "Elastic Port " + elasticPort
    correct_paths = raw_input("Are these correct?\n1: Yes\n2: Update IP\n3: Update port\n")
    correct_paths = int(correct_paths)
    if correct_paths == 2:
		elasticIP = raw_input("Enter new IP: ")
    elif correct_paths == 3:
        elasticPort = raw_input("Enter new port #: ")
    elif correct_paths == 1:
		break
    else:
		print "You entered an invalid selection"

es = Elasticsearch([elasticIP], port=elasticPort)

invfilepath = "./inv.txt"
with open(invfilepath,"r") as f:
    for line in f:
        print "Updating _id " + line
        id = line.rstrip()
        es.update(index="volhunter", doc_type="doc", id=id, body={"doc": {"investigated":"true"}})
        #file_process = os.path.abspath(os.path.join(dirpath, f))
