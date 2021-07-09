# VolHunter #

A tool for volatility analysis at scale.
![alt text](https://user-images.githubusercontent.com/39749344/59982884-6ae23a00-95de-11e9-815b-25443e51b24c.JPG)
# TO-DOs #

- Add logic to python scripts to support user/pass authentication in Elastic
- Recompile x86 & x64 Volatility exe's
- Publish EQL queries
- Add logic to DLLLIST tagger for older (<= Win7) to check if LoadTime is NOT a parameter for parsing purposes
- ~~Update VolHunter.psm1 Format-VHReport to reflect new plugins in use~~
- ~~Provide example report prior to formatting~~
- Update VHSwarm to add error handling
     - What if 1+ of intermediaries is offline or doesn't respond?
     - Can we have "backup" intermediaries?
     - Add functions to utilize intermediares to collect outputs, log files, monitor targets, and delete output from targets
     - Add graceful "abort" function to kill VolHunter on all targets if execution is borked
- ~~Add try/except to convert.py to handle malformed artifacts in "scan" type outputs~~
- ~~Debug dlllist parsing that incorrectly tags dlllist addresses and process names~~
- ~~Add MITRE CAR rules into post processing script~~
- ~~Psxview parsing has current bug for nonstandard #s of fields found (Wkstn-80 577936 found as a process.name IN MALEX-10)~~
- ~~Gather sample data for netscan plugin in order to improve processing logic for different output cases~~
- Add function to include date/time field that sample was taken
- Add further "known" and "unknown" items to tagger.py
     - ~~Process lineage standards~~
     - Tag non-standard DLLs per process
     - Rules for psxview output
     - ~~When tagging a "NonSys32DLL" include that path in the tags array~~
     - Improve "FuncPrologue" tag identification logic to include all three lines necessary for a function prologue
- Consider additional plugins
     - Svcscan - To identify unique services across systems
- ~~Include a .zip file with all scripts & folder structures laid out (minus memory dumping tool for copyright reasons)~~

5C!
