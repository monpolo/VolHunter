import json
from elasticsearch import Elasticsearch

def parentname(host, port):
    es = Elasticsearch([host], port=port)

    ### Update parent.process.name to pslist items
    res = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "pslist"}}})
    print("%d PSLIST entries to update parent.process.name" % res['hits']['total'])
    for doc in res['hits']['hits']:
        if (doc['_source']['process.name'] != "System"):
            searchedppid = doc['_source']['process.ppid']
            searchedhostname = doc['_source']['hostname']
            ppidres = es.search(index="volhunter", body={ "query": {"bool": {"must": [{"match": {"plugin": "pslist"} }, {"match": {"process.pid": searchedppid} }, {"match":{"hostname.keyword": searchedhostname}} ] } } })
            #bob['_source']['process.name'] is now our doc['_source']['parent.process.name']
            for bob in ppidres['hits']['hits']:
                es.update(index="volhunter", doc_type="doc", id=doc["_id"], body={"doc": {"process.parent.name":bob['_source']['process.name']}})
            if (ppidres['hits']['total'] == 0):
                es.update(index="volhunter", doc_type="doc", id=doc["_id"], body={"doc": {"process.parent.name": "NULL"}})

    res = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "cmdline"}}})
    print("%d CMDLINE entries to update parent.process.name" % res['hits']['total'])
    for doc in res['hits']['hits']:
        searchedpid = doc['_source']['process.pid']
        searchedhostname = doc['_source']['hostname']
        searchedname = doc['_source']['process.name']
        ppidres = es.search(index="volhunter", body={"query": {"bool": {"must": [{"match": {"plugin": "pslist"} }, {"match": {"process.pid": searchedpid} }, {"match":{"hostname.keyword": searchedhostname}}, {"match":{"process.name.keyword": searchedname}} ] } } })
        for psdoc in ppidres['hits']['hits']:
            es.update(index="volhunter", doc_type="doc", id=doc["_id"], body={"doc": {"process.parent.name": psdoc['_source']['process.parent.name']}})

def lineageInv(host, port):
    es = Elasticsearch([host], port=port)
    ### Update investigated field for standard process lineage
    print "Filtering standard process lineage"
    res = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "pslist"}}})

    for doc in res['hits']['hits']:
        #Userinit -> Explorer
        if (doc['_source']['process.name'].lower() == "explorer.exe"):
            if (doc['_source']['process.parent.name'].lower() == "userinit.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #Wininit -> Services
        if (doc['_source']['process.name'].lower() == "services.exe"):
            if (doc['_source']['process.parent.name'].lower() == "wininit.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #Wininit -> LSASS
        if (doc['_source']['process.name'].lower() == "lsass.exe"):
            if (doc['_source']['process.parent.name'].lower() == "wininit.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #SMSS -> csrss
        if (doc['_source']['process.name'].lower() == "csrss.exe"):
            if (doc['_source']['process.parent.name'].lower() == "smss.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #SMSS -> SMSS
        if (doc['_source']['process.name'].lower() == "smss.exe"):
            if (doc['_source']['process.parent.name'].lower() == "smss.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #System -> SMSS
        if (doc['_source']['process.name'].lower() == "smss.exe"):
            if (doc['_source']['process.parent.name'].lower() == "system"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #services -> svchost
        if (doc['_source']['process.name'].lower() == "svchost.exe"):
            if (doc['_source']['process.parent.name'].lower() == "services.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #smss -> Wininit
        if (doc['_source']['process.name'].lower() == "wininit.exe"):
            if (doc['_source']['process.parent.name'].lower() == "smss.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #svchost -> runtimebroker
        if (doc['_source']['process.name'].lower() == "runtimebroker.exe"):
            if (doc['_source']['process.parent.name'].lower() == "svchost.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #wininit -> lsaiso
        if (doc['_source']['process.name'].lower() == "lsaiso.exe"):
            if (doc['_source']['process.parent.name'].lower() == "wininit.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #svchost -> taskhostw
        if (doc['_source']['process.name'].lower() == "taskhostw.exe"):
            if (doc['_source']['process.parent.name'].lower() == "svchost.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})
        #smss -> winlogon
        if (doc['_source']['process.name'].lower() == "winlogon.exe"):
            if (doc['_source']['process.parent.name'].lower() == "smss.exe"):
                es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc": {"investigated":"true"}})

def carUpdate(tag, es, doc):
    tagArray = []
    tagArray.append(tag)
    if(doc['_source']['tags'] != ""):
        tagArray.append(doc['_source']['tags'])
    if tag not in doc['_source']['tags']:
        es.update(index="volhunter", doc_type="doc", id=doc['_id'], body={"doc" : {"tags":tagArray} })
        es.indices.refresh(index="volhunter")

def carRules(host, port):
    es = Elasticsearch([host], port=port)
    # CAR Analytics based on PSLIST output
    print "Running PSLIST Analytics"
    pslistres = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "pslist"}}})

    for doc in pslistres['hits']['hits']:
        #CAR-2013-02-003: Processes Spawning CMD
        if (doc['_source']['process.name'].lower() == "cmd.exe") and (doc['_source']['process.parent.name'].lower() != "explorer.exe"):
            carUpdate("CAR-2013-02-003-Processes-Spawning-CMD", es, doc)

        #CAR-2013-03-001: Reg.exe spawned from command shell
        if (doc['_source']['process.name'].lower() == "reg.exe") and (doc['_source']['process.parent.name'].lower() == "cmd.exe" or doc['_source']['process.parent.name'].lower() == "powershell.exe"):
            carUpdate("CAR-2013-03-001-CMD-Spawns-Reg", es, doc)

        #CAR-2014-04-003: Processes Spawning Powershell
        if (doc['_source']['process.name'].lower() == "powershell.exe") and (doc['_source']['process.parent.name'].lower() != "explorer.exe"):
            carUpdate("CAR-2014-04-003-Processes-Spawning-Powershell", es, doc)

        #CAR-2013-07-002: RDP Receiver
        if (doc['_source']['process.name'].lower() == "rdpclip.exe"):
            carUpdate("CAR-2013-07-002-RDP-Receiver", es, doc)

        #CAR-2014-11-004: Remote Powershell Sessions
        if (doc['_source']['process.name'].lower() == "powershell.exe") and (doc['_source']['process.parent.name'].lower() == "svchost.exe"):
            carUpdate("CAR-2014-11-004-Remote-PS-Session", es, doc)

        #CAR-2014-12-001: Remotely Launched EXE via WMI
        if (doc['_source']['process.parent.name'].lower() == "wmiprvse.exe"):
            carUpdate("CAR-2014-12-001-Remote-Execution-via-WMI", es, doc)

    # CAR Analytics based on DLLLIST output
    print "Running DLLLIST Analytics"
    dlllistres = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "dlllist"}}})

    for doc in dlllistres['hits']['hits']:
        #CAR-2019-04-003: Squiblydoo - COM Scriptlets
        if (doc['_source']['process.name'].lower() == "regsvr32.exe") and ("scrobj.dll" in doc['_source']['dlllist.path'].lower()):
            carUpdate("CAR-2019-04-003-COM-Scriptlets", es, doc)

    # CAR Analytics based on CMDLINE output
    print "Running CMDLINE Analytics"
    cmdlineres = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "cmdline"}}})

    for doc in cmdlineres['hits']['hits']:
        #CAR-2013-05-002: Suspicious Run Locations - Recycle Bin
        if ("recycler" in doc['_source']['process.arguments'].lower()):
            carUpdate("CAR-2013-05-002-RecycleBin-Execution", es, doc)

        #CAR-2013-05-002: Suspicious Run Locations - SystemVolumeInformation
        if ("systemvolumeinformation" in doc['_source']['process.arguments'].lower()):
            carUpdate("CAR-2013-05-002-systemvolumeinformation-Execution", es, doc)

        #CAR-2013-05-002: Suspicious Run Locations - Win/Tasks
        if ("tasks" in doc['_source']['process.arguments'].lower()):
            carUpdate("CAR-2013-05-002-Windows-Tasks-Execution", es, doc)

        #CAR-2013-05-002: Suspicious Run Locations - Win/Debug
        if ("debug" in doc['_source']['process.arguments'].lower()):
            carUpdate("CAR-2013-05-002-Windows-Debug-Execution", es, doc)

        #CAR-2013-05-004: Execution with AT Jobs
        if ("\\at.exe" in doc['_source']['process.arguments'].lower()):
            carUpdate("CAR-2013-05-004-AT-Job-Execution", es, doc)

        #CAR-2013-08-001: Schtasks
        a = ['/create', '/run', '/query', '/delete', '/change', '/end']
        if (doc['_source']['process.name'].lower() == "schtasks.exe"):
            if any(x in doc['_source']['process.arguments'].lower() for x in a):
                carUpdate("CAR-2013-08-001-schtasks", es, doc)

        #CAR-2019-04-002.1 Generic Regsvr32
        if (doc['_source']['process.pid'].lower() != "null"):
            if (doc['_source']['process.parent.name'].lower() == "regsvr32.exe") and (doc['_source']['process.name'].lower() == "regsvr32.exe") and ("regsvr32.exe" not in (doc['_source']['process.arguments']).lower()):
                carUpdate("CAR-2019-04-002.1-Generic-Regsvr32", es, doc)
                #CAR-2019-04-002.2 Regsvr32 odd children
            if (doc['_source']['process.parent.name'].lower() == "regsvr32.exe") and (doc['_source']['process.name'].lower() != "regsvr32.exe") and (doc['_source']['process.name'].lower() != "werfault.exe") and (doc['_source']['process.name'].lower() != "wevtutil.exe"):
                carUpdate("CAR-2019-04-002.2-Regsvr32-Odd-Children", es, doc)

    # CAR Analytics based on NETSCAN output
    print "Running NETSCAN Analytics"
    netscanres = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "netscan"}}})

    for doc in netscanres['hits']['hits']:
        #CAR-2013-07-002: RDP Initiator
        if (doc['_source']['process.name'].lower() == "mstsc.exe"):
            carUpdate("CAR-2013-07-002-RDP-Initiator", es, doc)

    # CAR Analytics based on LDRMODULES output
    print "Running LDRMODULES Analytics"
    ldrmodulesres = es.search(index="volhunter", body={'size' : 10000, "query": {"match": {"plugin": "ldrmodules"}}})

    for doc in ldrmodulesres['hits']['hits']:
            #CAR-2019-04-002.3 Regsvr32 unsigned DLLs
            if (doc['_source']['process.name'].lower() == "regsvr32.exe") and ("program files" not in doc['_source']['module.path'].lower()) and ("windows" not in doc['_source']['module.path'].lower()):
                carUpdate("CAR-2019-04-002.3-Regsvr32-Unsigned-DLLs", es, doc)
