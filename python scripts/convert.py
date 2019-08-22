from os import listdir
import os.path
import json

def printError(errLine, errMessage, f):
	print errMessage
	correctChoice = 0
	while correctChoice != 1:
		print errLine
		errorChoice = raw_input("Error, [d]iscard data and continue, [a]bort: ")
		if (errorChoice == "d"):
			correctChoice = 1
			return
		elif (errorChoice == "a"):
			f.close()
			exit()
		else:
			print "Invalid Input"

def cmdline(input_path, output_path, autoDiscard):
	delin = "************************************************************************"
	CL = "Command line : "
	d = {"process.name" : "null" , "process.pid" : "null" , "process.arguments" : "null" , "hostname" : "null" , "plugin" : "cmdline" , "investigated" : "false", "tags" : ""}

	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	input_file = os.path.basename(input_path)

	filename = input_file.replace("cmdline-","").replace(".txt","")
	print "CMDLINE Processing " + input_file
	firstline = 1

	with open(input_path,"r") as f:
		for line in f:
			try:
				#print line
				if (firstline == 1):
					firstline = 0
					continue
				if line.startswith(delin):
					d['hostname'] = filename
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"process.name" : "null" , "process.pid" : "null" , "process.arguments" : "null" , "hostname" : "null" , "plugin" : "cmdline" , "investigated" : "false", "tags" : ""}
				else:
					if line.startswith(CL):
						args = line.replace(CL,'')
						d['process.arguments'] = args.rstrip().replace('"',"'")
					else:
						#print line
						proc = line.split()
						#print proc
						if proc[0].rstrip() == "pid:":
							raise ValueError('Suspected no process name found')
						if int(proc[2].rstrip()) > 1000000:
							print "TOO HIGH OF PID " + proc[2].rstrip()
							raise ValueError('PID too high')
						d['process.name'] = proc[0].rstrip()
						d['process.pid'] = proc[2].rstrip()
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)

	d['hostname'] = filename
	output_file.write(json.dumps(d))
	output_file.write("\n")
	d = {"process.name" : "null" , "process.pid" : "null" , "process.arguments" : "null" , "hostname" : "null" , "plugin" : "cmdline" , "investigated" : "false", "tags" : ""}
	f.close()
	output_file.close()
	return;

def ssdt(input_path, output_path, autoDiscard):
	d = {"ssdt.function" : "null" , "ssdt.owner" : "null" , "ssdt.entry" : "null" , "ssdt.address" : "null" , "hostname" : "null" , "plugin" : "ssdt" , "investigated" : "false", "tags" : ""}

	#File to write to
	output_file = open(output_path,"a+")
	input_file = os.path.basename(input_path)
	filename = input_file.replace("ssdt-","").replace(".txt","")
	print "SSDT Processing " + input_file

	with open(input_path,"r") as f:
		for line in f:
			try:
				if not "Entry " in line:
					continue
				else:
					ssdt = line.split()
					d['ssdt.function'] = ssdt[3]
					d['ssdt.owner'] = ssdt[6]
					d['ssdt.entry'] = ssdt[1].replace(":","")
					d['ssdt.address'] = ssdt[2]
					d['hostname'] = filename
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"ssdt.function" : "null" , "ssdt.owner" : "null" , "ssdt.entry" : "null" , "ssdt.address" : "null" , "hostname" : "null" , "plugin" : "ssdt" , "investigated" : "false", "tags" : ""}
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()
	output_file.close()
	return;

def malfind(input_path, output_path, autoDiscard):
	d = {"process.name" : "null" , "process.pid" : "null" , "malfind.address" : "null" , "hostname" : "null" , "plugin" : "malfind" , "investigated" : "false" , "malfind.ascii" : "null" , "malfind.assembly" : "null" , "tags" : ""}
	tracktwo = "null"
	trackthree = "null"
	tagarray = []
	#File to write to
	output_file = open(output_path,"a+")
	input_file = os.path.basename(input_path)

	filename = input_file.replace("malfind-","").replace(".txt","")
	print "MALFIND Processing " + input_file
	group_track = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				#print line
				if ((not line) or (line == "\n")):
					group_track += 1
					if group_track == 3:
						#print "Group track is 3"
						group_track = 0
						d['hostname'] = filename
						tracktwoarray = tracktwo.split("\n")
						trackthreearray = trackthree.split("\n")
						d['malfind.ascii'] = tracktwoarray
						d['malfind.assembly'] = trackthreearray
						#CHECK FOR MZ HEADERS
						if any("MZ" in s for s in d['malfind.ascii']):
							tagarray.append("MZHEADER")
						#CHECK FOR FUNCTION PROLOGUE
						if any("MOV EBP, ESP" in s for s in d['malfind.assembly']):
							tagarray.append("FUNCPROLOGUE")
						d['tags'] = tagarray
						output_file.write(json.dumps(d))
						output_file.write("\n")
						tagarray = []
						tracktwo = "null"
						trackthree = "null"

						d = {"process.name" : "null" , "process.pid" : "null" , "malfind.address" : "null" , "hostname" : "null" , "plugin" : "malfind" , "investigated" : "false" , "malfind.ascii" : "null" , "malfind.assembly" : "null" , "tags" : ""}
						continue
				else:
					if group_track == 0:
						#print "Group track is 0"
						if "Process: " in line:
							data = line.split()
							d['process.name'] = data[1]
							d['process.pid'] = data[3]
							d['malfind.address'] = data[5]
					if group_track == 1:
						#print "Group track is 1"
						if tracktwo == "null":
							tracktwo = line.replace('"',"'").replace("[","{").replace("]","}")
						else:
							tracktwo = tracktwo + line.replace('"',"'").replace("[","{").replace("]","}")
					if group_track == 2:
						#print "Group track is 2"
						if trackthree == "null":
							trackthree = line.replace('"',"'").replace("[","{").replace("]","}")
						else:
							trackthree = trackthree + line.replace('"',"'").replace("[","{").replace("]","}")
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()
	output_file.close()
	return;

def psxview(input_path, output_path, autoDiscard):
	d = {"process.offset.physical" : "null" , "process.name" : "null" , "process.pid" : "null" , "psxview.pslist" : "null" , "hostname" : "null" , "plugin" : "psxview" , "investigated" : "false" , "psxview.psscan" : "null" , "psxview.thrdproc" : "null" , "psxview.pspcid" : "null" , "psxview.csrss" : "null" , "psxview.session" : "null" , "psxview.deskthrd" : "null" , "psxview.exittime" : "null", "tags" : ""}

	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	#input_path = "/home/sansforensics/Desktop/vh/vhoutput/psxview-twit.txt"
	input_file = os.path.basename(input_path)

	filename = input_file.replace("psxview-","").replace(".txt","")
	print "PSXVIEW Processing " + input_file
	openlines = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				if openlines < 2:
					openlines += 1
				else:
					data = line.split()
					d['hostname'] = filename
					if len(data) == 13:
						d['process.offset.physical'] = data[0]
						d['process.name'] = data[1]
						d['process.pid'] = data[2]
						d['psxview.pslist'] = data[3]
						d['psxview.psscan'] = data[4]
						d['psxview.thrdproc'] = data[5]
						d['psxview.pspcid'] = data[6]
						d['psxview.csrss'] = data[7]
						d['psxview.session'] = data[8]
						d['psxview.deskthrd'] = data[9]
						d['psxview.exittime'] = data[10] + " " + data[11] + " " + data[12]
					#Missing process.name and timestamp
					elif len(data) == 9:
						d['process.offset.physical'] = data[0]
						#d['process.name'] = data[1]
						d['process.pid'] = data[1]
						d['psxview.pslist'] = data[2]
						d['psxview.psscan'] = data[3]
						d['psxview.thrdproc'] = data[4]
						d['psxview.pspcid'] = data[5]
						d['psxview.csrss'] = data[6]
						d['psxview.session'] = data[7]
						d['psxview.deskthrd'] = data[8]
						d['psxview.exittime'] = "null"
					#Missing timestamp
					elif len(data) == 10:
						d['process.offset.physical'] = data[0]
						d['process.name'] = data[1]
						d['process.pid'] = data[2]
						d['psxview.pslist'] = data[3]
						d['psxview.psscan'] = data[4]
						d['psxview.thrdproc'] = data[5]
						d['psxview.pspcid'] = data[6]
						d['psxview.csrss'] = data[7]
						d['psxview.session'] = data[8]
						d['psxview.deskthrd'] = data[9]
						d['psxview.exittime'] = "null"
					else:
						raise ValueError('Suspected bad scan result with incorrect number of fields')
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"process.offset.physical" : "null" , "process.name" : "null" , "process.pid" : "null" , "psxview.pslist" : "null" , "hostname" : "null" , "plugin" : "psxview" , "investigated" : "false" , "psxview.psscan" : "null" , "psxview.thrdproc" : "null" , "psxview.pspcid" : "null" , "psxview.csrss" : "null" , "psxview.session" : "null" , "psxview.deskthrd" : "null" , "psxview.exittime" : "null", "tags" : ""}
					continue
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()

def pslist(input_path, output_path, autoDiscard):
	d = {"process.offset.virtual" : "null" , "process.name" : "null" , "process.pid" : "null" , "process.ppid" : "null" , "hostname" : "null" , "plugin" : "pslist" , "investigated" : "false" , "process.threads" : "null" , "process.handles" : "null" , "process.session" : "null" , "process.wow64" : "null" , "process.starttime" : "null" , "process.exittime" : "null", "process.parent.name" : "null", "tags" : ""}
	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	#input_path = "/home/sansforensics/Desktop/vh/vhoutput/pslist-twit.txt"
	input_file = os.path.basename(input_path)

	filename = input_file.replace("pslist-","").replace(".txt","")
	print "PSLIST Processing " + input_file
	openlines = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				if openlines < 2:
					openlines += 1
				else:
					data = line.split()
					if(len(data) == 7):
						raise ValueError('Suspected false EPROCESS artifact')
					d['process.offset.virtual'] = data[0]
					d['process.name'] = data[1]
					d['process.pid'] = data[2]
					d['process.ppid'] = data[3]
					d['process.threads'] = data[4]
					d['process.handles'] = data[5]
					d['process.session'] = data[6]
					d['process.wow64'] = data[7]
					if len(data) > 8:
						d['process.starttime'] = data[8] + " " + data[9] + " " + data[10]
						d['hostname'] = filename
					if len(data) == 14:
						d['process.exittime'] = data[11] + " " + data[12] + " " + data[13]
					else:
						d['process.exittime'] = "null"
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"process.offset.virtual" : "null" , "process.name" : "null" , "process.pid" : "null" , "process.ppid" : "null" , "hostname" : "null" , "plugin" : "pslist" , "investigated" : "false" , "process.threads" : "null" , "process.handles" : "null" , "process.session" : "null" , "process.wow64" : "null" , "process.starttime" : "null" , "process.exittime" : "null", "process.parent.name" : "null", "tags" : ""}
					continue
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()

def nonblank_lines(f):
	for l in f:
		line = l.rstrip()
		if line:
			yield line

def dlllist(input_path, output_path, autoDiscard):
	CL = "Command line :"
	basearray = []
	sizearray = []
	loadcountarray = []
	loadtimearray = []
	patharray = []
	tagarray = []

	d = {"process.name" : "null" , "process.pid" : "null" , "process.arguments" : "null" , "hostname" : "null" , "plugin" : "dlllist" , "investigated" : "false" , "dlllist.base" : "null" , "dlllist.size" : "null" , "dlllist.loadcount" : "null" , "dlllist.loadtime" : "null" , "dlllist.path" : "null" , "tags" : ""}
	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	input_file = os.path.basename(input_path)

	filename = input_file.replace("dlllist-","").replace(".txt","")
	print "DLLLIST Processing " + input_file
	firstline = 1
	groupcount = 0

	with open(input_path,"r") as f_in:
		for liners in nonblank_lines(f_in):
			try:
				line = liners.rstrip()
				if (firstline == 1):
					firstline = 0
					continue
				if "*****" in line:
					d['hostname'] = filename
					d['dlllist.base'] = basearray
					d['dlllist.size'] = sizearray
					d['dlllist.loadcount'] = loadcountarray
					d['dlllist.loadtime'] = loadtimearray
					d['dlllist.path'] = patharray
					#Search for non system32 paths
					for s in d['dlllist.path']:
						if (("C:" not in s.upper()) and ("WINDOWS" not in s.upper()) and (".EXE" not in s.upper()) and ("NULL" not in s.upper()) and (s != "")):
							tagarray.append("InjectedDLL")
							tagarray.append(s)
							d['tags'] = tagarray
						elif (("SYSTEM32" not in s.upper()) and ("NULL" not in s.upper()) and (".EXE" not in s.upper()) and (s != "") and ("WINSXS" not in s.upper())  and ("SYSWOW64" not in s.upper())  and ("WINDOWS\\MICROSOFT.NET" not in s.upper())  and ("WINDOWS\\ASSEMBLY" not in s.upper())):
							tagarray.append("NonSys32DLL")
							tagarray.append(s)
							d['tags'] = tagarray

					groupcount = 0
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"process.name" : "null" , "process.pid" : "null" , "process.arguments" : "null" , "hostname" : "null" , "plugin" : "dlllist" , "investigated" : "false" , "dlllist.base" : "null" , "dlllist.size" : "null" , "dlllist.loadcount" : "null" , "dlllist.loadtime" : "null" , "dlllist.path" : "null" , "tags" : ""}
					basearray = []
					sizearray = []
					loadcountarray = []
					loadtimearray = []
					patharray = []
					tagarray = []
				else:
					if groupcount == 0:
						if line.startswith(CL):
							#print "IN CL START"
							args = line.replace(CL,'')
							#print "CL is "
							#print args
							d['process.arguments'] = args.rstrip().replace('"',"'")
							groupcount += 1
						elif line.startswith("Unable to read PEB"):
							#print "IN UNABLE"
							continue
						else:
							proc = line.split()
							#print "TEST 2: " + line
							if proc[0].rstrip() == "pid:":
								raise ValueError('Suspected no process name found')
							if (int(proc[2].rstrip()) > 400000):
								raise ValueError('Non realistic PID value')
							d['process.name'] = proc[0].rstrip()
							d['process.pid'] = proc[2].rstrip()
					else:
						if line.startswith("Base"):
							#print "IN START WITH BASE"
							continue
						elif line.startswith("-----"):
							#print "IN -----"
							continue
						else:
							#print "GC > 0, should be seeing DLLs"
							data = line.split()
							#print "data len ", len(data)
							#print data
							basearray.append(data[0])
							sizearray.append(data[1])
							loadcountarray.append(data[2])
							if len(data) == 3:
								patharray.append("null")
								loadtimearray.append("null")
							elif (data[3].startswith("2") or data[3].startswith("1")):
								timeval = data[3] + data[4] + data[5]
								loadtimearray.append(timeval)
								#6-end of array goes to path
								ind = 6
								pathval = ""
								while(ind < len(data)):
									pathval = pathval + " " + data[ind]
									ind = ind + 1
								patharray.append(pathval)
							else: #3-end of array REST OF LENGTH GOES TO PATH
								ind = 3
								pathval = ""
								while(ind < len(data)):
									pathval = pathval + " " + data[ind]
									ind = ind + 1
								patharray.append(pathval)
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)

	d['hostname'] = filename
	d['dlllist.base'] = basearray
	d['dlllist.size'] = sizearray
	d['dlllist.loadcount'] = loadcountarray
	d['dlllist.loadtime'] = loadtimearray
	d['dlllist.path'] = patharray
	#Search for non system32 paths
	for s in d['dlllist.path']:
		if (("SYSTEM32" not in s.upper()) and ("NULL" not in s.upper()) and (".EXE" not in s.upper()) and (s != "") and ("WINSXS" not in s.upper())  and ("SYSWOW64" not in s.upper())  and ("WINDOWS\\MICROSOFT.NET" not in s.upper())  and ("WINDOWS\\ASSEMBLY" not in s.upper())):
			tagarray.append("NonSys32DLL")
			tagarray.append(s)
			d['tags'] = tagarray
		if (("C:" not in s.upper()) and (".EXE" not in s.upper()) and ("NULL" not in s.upper()) and (s != "")):
			tagarray.append("InjectedDLL")
			tagarray.append(s)
			d['tags'] = tagarray
	groupcount = 0
	output_file.write(json.dumps(d))
	output_file.write("\n")

	f_in.close()
	output_file.close()

def timers(input_path, output_path, autoDiscard):
	d = {"timer.offset.virtual" : "null" , "timer.duetime" : "null" , "timer.period" : "null" , "timer.signaled" : "null" , "hostname" : "null" , "plugin" : "timers" , "investigated" : "false" , "timer.routine" : "null" , "timer.module" : "null", "tags" : ""}
	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	input_file = os.path.basename(input_path)

	filename = input_file.replace("timers-","").replace(".txt","")
	print "TIMERS Processing " + input_file
	openlines = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				if openlines < 2:
					openlines += 1
				else:
					data = line.split()
					d['timer.offset.virtual'] = data[0]
					d['timer.duetime'] = data[1]
					d['timer.period'] = data[2]
					d['timer.signaled'] = data[3]
					d['timer.routine'] = data[4]
					d['timer.module'] = data[5]
					d['hostname'] = filename
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"timer.offset.virtual" : "null" , "timer.duetime" : "null" , "timer.period" : "null" , "timer.signaled" : "null" , "hostname" : "null" , "plugin" : "timers" , "investigated" : "false" , "timer.routine" : "null" , "timer.module" : "null", "tags" : ""}
					continue
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()
	output_file.close()

def ldrmodules(input_path, output_path, autoDiscard):
	d = {"process.pid" : "null" , "process.name" : "null" , "module.address.virtual" : "null" , "module.inload" : "null" , "hostname" : "null" , "plugin" : "ldrmodules" , "investigated" : "false" , "module.ininit" : "null" , "module.inmem" : "null" , "module.path" : "null", "tags" : ""}
	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	input_file = os.path.basename(input_path)

	filename = input_file.replace("ldrmodules-","").replace(".txt","")
	print "LDRMODULES Processing " + input_file
	openlines = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				if openlines < 2:
					openlines += 1
				else:
					data = line.split()
					d['process.pid'] = data[0]
					d['process.name'] = data[1]
					d['module.address.virtual'] = data[2]
					d['module.inload'] = data[3]
					d['module.ininit'] = data[4]
					d['module.inmem'] = data[5]
					xcount = 6
					while xcount < len(data):
						if xcount == 6:
							d['module.path'] = data[6]
						else:
							d['module.path'] = d['module.path'] + " " + data[xcount]
						xcount += 1
					d['hostname'] = filename

					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"process.pid" : "null" , "process.name" : "null" , "module.address.virtual" : "null" , "module.inload" : "null" , "hostname" : "null" , "plugin" : "ldrmodules" , "investigated" : "false" , "module.ininit" : "null" , "module.inmem" : "null" , "module.path" : "null", "tags" : ""}
					continue
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()
	output_file.close()

def netscan(input_path, output_path, autoDiscard):
	d = {"net.offset.physical" : "null" , "net.protocol" : "null" , "net.local" : "null" , "net.foreign" : "null" , "hostname" : "null" , "plugin" : "netscan" , "investigated" : "false" , "net.state" : "null" , "process.pid" : "null" , "process.name" : "null" , "net.starttime" : "null", "tags" : "" }
	#File to write to
	output_file = open(output_path,"a+")
	#Filename of input file
	input_file = os.path.basename(input_path)
	filename = input_file.replace("netscan-","").replace(".txt","")
	print "NETSCAN Processing " + input_file
	openlines = 0

	with open(input_path,"r") as f:
		for line in f:
			try:
				if openlines < 1:
					openlines += 1
				else:
					data = line.split()
					d['hostname'] = filename
					d['net.offset.physical'] = data[0]
					d['net.protocol'] = data[1]
					d['net.local'] = data[2]
					d['net.foreign'] = data[3]
					#All fields present - 10
					#No time, all others present - 7
					if (len(data) == 10 or len(data) == 7):
						d['net.state'] = data[4]
						d['process.pid'] = data[5]
						d['process.name'] = data[6]
						if len(data) == 10:
							d['net.starttime'] = data[7] + " " + data[8] + " " + data[9]
					#No owner, no time
					elif len(data) == 6:
						d['net.state'] = data[4]
						d['process.pid'] = data[5]
					#No state, yes date/time
					else:
						#Likely a glitched scan result with no process.name
						if data[4] == "CLOSED":
							raise ValueError('Suspected bad scan result with false PID and no process name')
						elif data[4] == "-1":
							raise ValueError('Suspected closed UDP artifact')
						d['net.state'] = "null"
						d['process.pid'] = data[4]
						d['process.name'] = data[5]
						d['net.starttime'] = data[6] + " " + data[7] + " " + data[8]
					if ((d['process.pid'] == "-1") or (d['process.pid'] == "0")):
						raise ValueError('False PID found')
					output_file.write(json.dumps(d))
					output_file.write("\n")
					d = {"net.offset.physical" : "null" , "net.protocol" : "null" , "net.local" : "null" , "net.foreign" : "null" , "hostname" : "null" , "plugin" : "netscan" , "investigated" : "false" , "net.state" : "null" , "process.pid" : "null" , "process.name" : "null" , "net.starttime" : "null", "tags" : "" }
					continue
			except Exception as e:
				if(autoDiscard == 1):
					print e
					print line
					continue
				else:
					printError(line, e, f)
	f.close()
