# VolHunter #

A tool for volatility analysis at scale.
![alt text](https://user-images.githubusercontent.com/39749344/59982884-6ae23a00-95de-11e9-815b-25443e51b24c.JPG)
# TO-DOs #

- Update VHSwarm to add error handling
     - What if 1+ of intermediaries is offline or doesn't respond?
     - Can we have "backup" intermediaries?
     - Add functions to utilize intermediares to collect outputs, log files, monitor targets, and delete output from targets
     - Add graceful "abort" function to kill VolHunter on all targets if execution is borked
- Add further "known" and "unknown" items to tagger.py 
     - Process lineage standards
     - Tag non-standard DLLs per process
     - Rules for psxview output

5C!
