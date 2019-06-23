import convert
import os.path
from os import listdir
from os.path import isfile, join

def jsonparsing(vhfilepath, output_folder):
	###BE SURE TO UPDATE THESE
	cmdline_output = output_folder + 'cmdline.json'
	dlllist_output = output_folder + 'dlllist.json'
	ldrmodules_output = output_folder + "ldrmodules.json"
	malfind_output = output_folder + 'malfind.json'
	netscan_output = output_folder + "netscan.json"
	pslist_output = output_folder + 'pslist.json'
	psxview_output = output_folder + 'psxview.json'
	ssdt_output = output_folder + 'ssdt.json'
	timers_output = output_folder + "timers.json"

	#Iterate over and process each file in the folder
	for dirpath,_,filenames in os.walk(vhfilepath):
		for f in filenames:
			file_process = os.path.abspath(os.path.join(dirpath, f))

			if "cmdline" in file_process:
				convert.cmdline(file_process, cmdline_output)
			elif "ssdt" in file_process:
				convert.ssdt(file_process, ssdt_output)
			elif "malfind" in file_process:
				convert.malfind(file_process, malfind_output)
			elif "psxview" in file_process:
				convert.psxview(file_process, psxview_output)
			elif "pslist" in file_process:
				convert.pslist(file_process, pslist_output)
			elif "dlllist" in file_process:
				convert.dlllist(file_process, dlllist_output)
			elif "timers" in file_process:
				convert.timers(file_process, timers_output)
			elif "ldrmodules" in file_process:
				convert.ldrmodules(file_process, ldrmodules_output)
			elif "netscan" in file_process:
				convert.netscan(file_process, netscan_output)
			else:
				print "Unknown file type: " + file_process
