#!/bin/python

import json, os
from elasticsearch import Elasticsearch, helpers

def main(ip, port, dirpath):
    es      = set_client(ip, port)
    records = set_records(dirpath)
    post_records(es, records, dirpath)

def set_client(ip, port):
    esclient = Elasticsearch([ip], port=port)
    testconnection(esclient)
    return esclient

def set_records(dirpath):
    records = []
    path    = dirpath + "/VHdata/output/"

    if len(os.listdir(path)) == 0:
        print("No files found in log diretory...\n")
        exit()

    for log in os.listdir(path):
        with open(path + log, 'r') as f:
            for line in f:
                records.append(line)

    print("Number of records to be indexed: ", len(records))
    return records

def post_records(es, records, dirpath):
    log_path     = dirpath + "/VHdata/output/"
    process_path = dirpath + "/VHdata/processed/"

    data = ({'_op_type': 'index',
             '_index': 'volhunter',
             '_type' : 'doc',
             '_source'   : record
             }
             for record in records)

    helpers.bulk(es, data)
    print("Index complete exiting, moving processed log files...")
    for log in os.listdir(log_path):
        os.rename(log_path + log, process_path + log)
    #print("Exiting...\n")
    #exit()

def testconnection(esclient):
    link = esclient.ping()
    if link:
        print("Uplink established...\n")
    else:
        os.system('clear')
        print("Unable to establish connection, exiting...")
        exit()

if __name__ == "__main__":
    os.system('clear')
    main()
