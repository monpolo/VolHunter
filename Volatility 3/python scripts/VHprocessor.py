import convert
import os.path
import shutil
import jsonformat
import encoder
import volindexer
import tagger
from os import listdir, getcwd
from os.path import isfile, join
from elasticsearch import Elasticsearch

dirpath = os.getcwd()
vhfilepath = dirpath + "/VHdata/gatheredlogs"
process_folder = dirpath + "/VHdata/converted/"
output_folder = dirpath + "/VHdata/output/"
elasticIP = "192.168.131.128"
elasticPort = "9200"

def format_and_ingest(vhfilepath, process_folder, output_folder, elasticIP, elasticPort, dirpath):
    #Validate that assumed paths are correct
    correct_paths = 0
    while correct_paths != 1:
        print "Root path " + dirpath
        print "VH data folder " + vhfilepath
        print "Processing folder " + process_folder
        print "Output folder " + output_folder
        correct_paths = raw_input("Are these paths correct?\n1: Yes\n2: Update folder path\n")
        correct_paths = int(correct_paths)
        if correct_paths == 2:
            dirpath = raw_input("Enter new path for processing: ")
            vhfilepath = dirpath + "/VHdata/gatheredlogs"
            process_folder = dirpath + "/VHdata/converted/"
            output_folder = dirpath + "/VHdata/output/"
            #vhfilepath = raw_input("Enter new path for VH data folder: ")
        #elif correct_paths == 3:
    		#process_folder = raw_input("Enter new path for processing folder: ")
        #elif correct_paths == 4:
            #output_folder = raw_input("Enter new path for output folder: ")
        elif correct_paths == 1:
    		break
        else:
    		print "You entered an invalid selection"

    #Convert to utf8 with Linux line endings
    encoder.encoding(vhfilepath, process_folder)
    print "Files converted. Pausing for your review..."
    raw_input()

    #Convert to json, remove processed files
    jsonformat.jsonparsing(process_folder, output_folder)
    print "Files formatted in json. Pausing for your review..."
    raw_input()
    for the_file in os.listdir(process_folder):
        file_path = os.path.join(process_folder, the_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
        except Exception as e:
            print(e)

    volindexer.main(elasticIP, elasticPort, dirpath)
    print "Files shipped. Pausing for your review..."
    print "### Ensure you have built the index in Kibana before proceeding ###"
    raw_input()

def validate_address(elasticIP, elasticPort):
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
    		return elasticIP, elasticPort;
        else:
    		print "You entered an invalid selection"

correct_paths = 0
elasticIP, elasticPort = validate_address(elasticIP, elasticPort)
while correct_paths != 4:
    correct_paths = raw_input("Choose a function:\n1) Convert, format, ingest data to Elastic\n2) Enrich data (ensure index is built in Kibana first)\n3) Run MITRE CAR Rules\n4) Quit\n999) Delete data from VolHunter Index CAN'T UNDO\n")
    correct_paths = int(correct_paths)
    if correct_paths == 1:
        format_and_ingest(vhfilepath, process_folder, output_folder, elasticIP, elasticPort, dirpath)
    elif correct_paths == 2:
        tagger.parentname(elasticIP, elasticPort)
        print "Parent process names updated. Pausing for your review..."
        raw_input()
        tagger.lineageInv(elasticIP, elasticPort)
        print "Set investigated for standard lineage. Pausing for your review..."
        raw_input()
    elif correct_paths == 3:
        tagger.carRules(elasticIP, elasticPort)
        print "CAR Rules complete. Pausing for your review..."
        raw_input()
    elif correct_paths == 4:
        print "Goodbye"
        exit()
    elif correct_paths == 999:
        es = Elasticsearch([elasticIP], port=elasticPort)
        es.indices.delete(index='volhunter', ignore=[400, 404])
    else:
        print "Invalid selection"
