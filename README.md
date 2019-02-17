# Logstash filters #

A Logstash filter configuration is located in the `filters` directory.  To use
the filters you must supply a config for input and output plugins appropriate
to your environment.  The filters also require a `source` field to be present
with a filename like `[path]/<plugin_name>-<hostname>.csv`.  This field is
created automatically if ingest is done with filebeats.

Messages that are correctly parsed by the filters will be tagged with
`valid-volhunter`.  This can be used to make sure only correctly parsed
data is sent to the output.

## Example Input/Output Configs ##

### Input ###
```
input {
  # recommended input is filebeats
  beats {
    port => 5044
  }
}
```

### Output ###
```
output {
  if "valid-volhunter" in [tags] {
    # use appropriate output plugin here
    stdout { codec => rubydebug }
  }
}
```

## Example Filebeat Config ##
This filebeat config can be used to ingest VolHunter output and send to
logstash.  The location of the VolHunter output files is set by the 
`INPUT_PATH` environment variable.

```YAML
#=========================== Filebeat inputs =============================

filebeat.inputs:

# Location of logs is set by the INPUT_PATH environment variable
- type: log
  paths:
    - ${INPUT_PATH}/*.csv

#================================ Outputs =====================================

output.logstash:
  hosts: ["localhost:5044"]
```