import convert
import os.path
import shutil
import jsonformat
import encoder
import volindexer
import tagger
from os import listdir
from os.path import isfile, join
#Test comment
vhfilepath = "./VHdata/gatheredlogs"
process_folder = "./VHdata/converted/"
output_folder = "./VHdata/output/"
elasticIP = "192.168.35.133"
elasticPort = "9200"

def format_and_ingest(vhfilepath, process_folder, output_folder, elasticIP, elasticPort):
    #Validate that assumed paths are correct
    correct_paths = 0
    while correct_paths != 1:
        print "VH data folder " + vhfilepath
        print "Processing folder " + process_folder
        print "Output folder " + output_folder
        correct_paths = raw_input("Are these paths correct?\n1: Yes\n2: Update VH data folder\n3: Update processing folder\n4: Update output folder\n")
        correct_paths = int(correct_paths)
        if correct_paths == 2:
            vhfilepath = raw_input("Enter new path for VH data folder: ")
        elif correct_paths == 3:
    		process_folder = raw_input("Enter new path for processing folder: ")
        elif correct_paths == 4:
            output_folder = raw_input("Enter new path for output folder: ")
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
    folder = process_folder
    for the_file in os.listdir(folder):
        file_path = os.path.join(folder, the_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
        except Exception as e:
            print(e)

    #Send to elasticsearch
    #elasticIP = "192.168.35.133"
    #elasticPort = "9200"
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
    volindexer.main(elasticIP, elasticPort)
    print "Files shipped. Pausing for your review..."
    print "### Ensure you have built the index in Kibana before proceeding ###"
    raw_input()

def post_process(elasticIP, elasticPort):
    #Send to elasticsearch
    #elasticIP = "192.168.35.133"
    #elasticPort = "9200"
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
    #Post process tagging
    tagger.parentname(elasticIP, elasticPort)
    print "Parent process names updated. Pausing for your review..."
    raw_input()
    tagger.lineageInv(elasticIP, elasticPort)
    print "Set investigated for standard lineage. Pausing for your review..."
    raw_input()
    print "All actions complete.\nHappy hunting!"
    #curl -X DELETE "192.168.35.133:9200/volhunter"

correct_paths = 0
while correct_paths != 3:
    correct_paths = raw_input("Choose a function:\n1) Convert, format, ingest data to Elastic\n2) Enrich data (ensure index is built in Kibana first)\n3) Run MITRE CAR Rules (SLOW)\n4) Quit\n")
    correct_paths = int(correct_paths)
    if correct_paths == 1:
        format_and_ingest(vhfilepath, process_folder, output_folder, elasticIP, elasticPort)
    elif correct_paths == 2:
        post_process(elasticIP, elasticPort)
    elif correct_paths == 3:
        tagger.carRules(elasticIP, elasticPort)
    elif correct_paths == 4:
        print "Goodbye"
        exit()
    else:
        print "Invalid selection"
