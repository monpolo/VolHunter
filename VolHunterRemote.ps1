<#
.SYNOPSIS

VolHunter aims to grab an image of live system memory, automate relevant 
volatility scans to gather initial triage datapoints, then send them to
an ElasticStack node for analysis via the Kicker script.

VolHunter can be run locally on a host system, to enable remote/mass scans,
utilize Kicker.ps1 to push VolHunter and relevant executables. 
Volatility and DumpIt (or chosen memory capturing tool such as Winpmem) 
need to be placed into C:\VolH\Tools

Outline of VolHunter Folder Structure:
C:\VolH\Image\     Stores memory dump file
C:\VolH\Output\    Stores raw & parsed volatility output
C:\VolH\Tools\     Stores volatility, VolHunterRemote, and DumpIt


.PARAMETER dumpFlag
An optional parameter, default value of false. When set to true
will run memory dumping utility and save in C:VolH\Image\

.PARAMETER volFlag
An optional parameter, default value of false. When set to true
will run all currently VolHunter usable volatility plugins

.NOTES
    Author: Michael "FUMBLES" Russell
    Date:   11 February 2019
    Version: 1.0.6
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$dumpFlag = $null,
    [Parameter(Mandatory=$False,Position=1)]
        [String]$Plugins=$null,
    [Parameter(Mandatory=$False,Position=2)]
        [String]$HumanReadable=$null,
    [Parameter(Mandatory=$False,Position=3)]
        [String]$Artifacts=$null
)

function Run-Vol{
    param( [string]$plugin, [string]$HR, [string]$logLocation, [string]$outputDir, [string]$imgLocation, [string]$volProfile )
    $command = "C:\VolH\Tools\volatility.exe"
    $hn = hostname
    Add-Content -Path $logLocation -Value "Running $plugin plugin`n"
    $start = Get-Date
    if($HR -eq "True"){
        $outFile = $outputDir + $plugin + "-" + $hn + ".txt"
        Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin" -RedirectStandardOutput $outFile -wait
    }
    else{
        $outFile = $outputDir + $plugin + "-" + $hn + ".xlsx"
        Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin --output=xlsx --output-file=$outFile" -wait
    }
    $end = Get-Date
    Add-Content -Path $logLocation -Value "$plugin plugin completed in $($end-$start) H:M:S.MS`n" 
}

Function Get-RandomDate {
    [cmdletbinding()]

    param([DateTime]$Min,[DateTime]$Max = [DateTime]::Now)
    $randomTicks = Get-Random -Minimum $Min.Ticks -Maximum $Max.Ticks
    New-Object DateTime($randomTicks)
}

##################
### Initialize ###
##################
$GLOBALSTART = Get-Date

### Static Variables ###
$hostName = hostname
$hostImg = $hostName + ".bin"
$baseDir = "C:\VolH\"
$imageDir = "C:\VolH\Image\"
$outputDir = "C:\VolH\Output\"
$toolDir = "C:\VolH\Tools\"
$imgLocation = "C:\VolH\Image\$hostImg"
$time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"+"T"+"HH:mm:ss.fff"+"Z")
$outer = 0
$inner = 0
$Architecture = 64
$OSVersi = [System.Environment]::OSVersion.Version
$logLocation = "C:\VolH\VHLog-$hostname.txt"

$vhlog = "Starting VolHunter`n"
Out-File -FilePath "$logLocation" -InputObject $vhlog -Encoding ASCII

###################################################################
### QUERY SYSTEM DETAILS TO DETERMINE --PROFILE= FOR VOLATILITY ###
###################################################################
Add-Content -Path "$logLocation" -Value "Determining x86 vs x64`n"
### Determine 32 vs 64 bit architecture
if([intptr]::size -eq 4){
    $Architecture = 86
}
Add-Content -Path "$logLocation" -Value "$hostname is x$Architecture`n"

### Get systeminfo ###
Add-Content -Path "$logLocation" -Value "Determining OS & Revision for Volatility profile`n"
$sysInfo = systeminfo.exe
$ram = (($sysinfo | select-string 'Total Physical Memory:').ToString().Split(':')[1].Trim()).Replace(" MB","")
$diskSpace = ( gwmi Win32_LogicalDisk -filter "deviceid='C:'" | Select DeviceID, @{Name="FreeMB";Expression={[math]::Round($_.Freespace/1MB,2)}} ).FreeMB
$osVersion = $sysInfo | select-string "OS Version"
$sysInfo = $sysInfo | select-string "OS Name"
Add-Content -Path "$logLocation" -Value "$hostname has $ram MB of RAM`n"
Add-Content -Path "$logLocation" -Value "$hostname has $diskSpace MB of free space on C:`n"
if($diskSpace -lt ([int]$freeRam + 2000) ){
    Add-Content -Path "C:VolH\VHLog.txt" -Value "Not enough free disk space`n"
    $volDone = "Not enough freespace on C:\ to run`n"
    Out-File -FilePath "C:\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
    return
}
Add-Content -Path "$logLocation" -Value "$osVersion `n"
Add-Content -Path "$logLocation" -Value "$sysInfo `n"

### Build Volatility --profile variable based on OSVersion.Version and systeminfo output ###
switch ($sysInfo){
    # Windows 10 Ver 10586/14393/15063+/none x86/64 #
    {$_ -like "*Windows 10*"} { 
        if(($osVersi.Build -ge 10586) -and ($osVersi.Build -lt 14393)){$volProfile = "Win10x"+$Architecture+"_10586"}
        elseif(($osVersi.Build -ge 14393) -and ($osVersi.Build -lt 15063)){$volProfile = "Win10x"+$Architecture+"_14393"}
        elseif(($osVersi.Build -ge 15063) -and ($osVersi.Build -lt 16299)){$volProfile = "Win10x"+$Architecture+"_15063"}
        elseif(($osVersi.Build -ge 16299) -and ($osVersi.Build -lt 17134)){$volProfile = "Win10x"+$Architecture+"_16299"}
        elseif(($osVersi.Build -ge 17134) -and ($osVersi.Build -lt 17763)){$volProfile = "Win10x"+$Architecture+"_17134"}
        elseif($osVersi.Build -eq 17763){$volProfile = "Win10x"+$Architecture+"_17763"}
        else{$volProfile = "Win10x"+$Architecture}
    }
    # Server 2016 Ver 14393 #
    {$_ -like "*Server 2016*"} { $volProfile = "Win2016x64_14393" } #End Server2016 switch
    # Server 2012 #
    {$_ -like "*Server 2012 *"} { $volProfile = "Win2012x64" }
    # Server 2012R2, Ver 18340 #
    {$_ -like "*Server 2012 R2*"} {
        if($osVersion -like "*18340*"){ $volProfile = "Win2012R2x64_18340" }
        else{ $volProfile = "Win2012R2x64" }
    }
    # Server 2008, SP1/2, x86/64 #
    {$_ -like "*Server*2008 Standard*"} {
        if($osVersion -like "*Service*Pack*1*"){ $volProfile = "Win2008SP1x"+$Architecture }
        else{ $volProfile = "Win2008SP2x"+$Architecture }
    }
    # Server 2008 R2 SP0/1 & SP1_23418 #
    {$_ -like "*Server 2008 R2*"} {
        if( !($osVersion -like "*Service Pack 1*") ){ $volProfile = "Win2008R2SP0x64" }
        elseif($osVersion -like "*23418*"){ $volProfile = "Win2008R2SP1x64_23418" }
        else{ $volProfile = "Win2008R2SP1x64" }
    }
    # Server 2003 SP0x86, SP1x86/64, SP2x86/64 #
    {$_ -like "Server 2003*"} {
        if($osVersion -like "*Service Pack 1*"){ $volProfile = "Win2003SP1x"+$Architecture }
        elseif($osVersion -like "*Service Pack 2*"){ $volProfile = "Win2003SP2x"+$Architecture }
        else{ $volProfile = "Win2003SP0x86" }
    }
    # Vista SP0/1/2 x86/x64 #
    {$_ -like "*Vista*"} {
        if($osVersion -like "*Service Pack 1*"){ $volProfile = "VistaSP1x"+$Architecture }
        elseif($osVersion -like "*Service Pack 2*"){ $volProfile = "VistaSP2x"+$Architecture }
        else{ $volProfile = "VistaSP0x"+$Architecture }
    }
    # Windows 7 SP0x64/86, SP1x64/86, SP1_23418x64/86 #
    {$_ -like "*Windows 7*"} {
        if( !($osVersion -like "*Service Pack*") ){ $volProfile = "Win7SP0x"+$Architecture }
        elseif($osVersion -like "*23418*"){ $volProfile = "Win7SP1x"+$Architecture + "_23418" }
        else{ $volProfile = "Win7SP1x"+$Architecture }
    }
    # Windows 8.1 #
    {$_ -like "*Windows 8.1*"} {
        if($osVersion -like "*18340*"){ $volProfile = "Win8SP1x64_18340" }
        else{ $volProfile = "Win8SP1x"+$Architecture }
    }
    # Windows 8 #
    {$_ -like "*Windows 8 *"} { $volProfile = "Win8SP0x"+$Architecture }

    default {$volProfile = "ERROR"}
}

Out-File -FilePath "C:\VolH\VolProfile.txt" -InputObject $volProfile -Encoding ASCII
Add-Content -Path "$logLocation" -Value "Volatility Profile = $volProfile `n"

if($volProfile -eq "ERROR"){ 
    Out-File -FilePath "C:\VolH\UNRECOGNIZEDPROFILE.txt" -InputObject $volProfile -Enocding ASCII
    $volDone = "VHRemote failed due to unrecognized profile"
    Out-File -FilePath "C:\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
    exit
}

###############################
### Run memory dumping tool ###
###############################
if($dumpFlag -eq "True"){
    
    if($Architecture -eq "64"){
        $dumpCommand = "C:\VolH\Tools\DumpIt-64.exe"
    }
    else{
        $dumpCommand = "C:\VolH\Tools\DumpIt-86.exe"
    }
    Add-Content -Path "$logLocation" -Value "Starting memory dump`n"
    $start = Get-Date
    Start-Process -Filepath $dumpCommand -ArgumentList "/Q /N /J /T RAW /OUTPUT $imgLocation" -wait
    $end = Get-Date
    $dumpDone = "DumpIt Completed"
    Out-File -FilePath "C:\VolH\DumpDone.txt" -InputObject $dumpDone -Encoding ASCII
    Add-Content -Path "$logLocation" -Value "Memory dump completed in $($end-$start) H:M:S.MS`n"
}

#####################################
### Gather artifacts as requested ###
#####################################
if( ($Artifacts -like "all") -or ($Artifacts -like "*pf*") -or ($Artifacts -like "*events*") -or ($Artifacts -like "*firewall*") -or ($Artifacts -like "*DAT*") -or ($Artifacts -like "*LNK*") -or ($Artifacts -like "*shim*") -or ($Artifacts -like "*state*") ){
    ### Gather Prefetch
    if( ($Artifacts -like "all") -or ($Artifacts -like "*pf*") ){
        New-Item -ItemType directory -Path ("C:\VolH\Output\Prefetch")
        Copy-Item -Path "C:\Windows\Prefetch\*.pf" -Destination "C:\VolH\Output\Prefetch\"
    }
    ### Gather Event Logs
    if( ($Artifacts -like "all") -or ($Artifacts -like "*events*") ){
        New-Item -ItemType directory -Path ("C:\VolH\Output\EventLogs")
        Copy-Item -Path "C:\Windows\System32\Winevt\Logs\*" -Destination "C:\VolH\Output\EventLogs\"
    }
    ### Gather Firewall Logs
    if( ($Artifacts -like "all") -or ($Artifacts -like "*firewall*") ){
        New-Item -ItemType directory -Path ("C:\VolH\Output\FWLogs")
        Copy-Item -Path "C:\Windows\System32\LogFiles\Firewall\*" -Destination "C:\VolH\Output\FWLogs\"
    }
    ### Gather NTUSER.DATs, won't work for currently logged in users
    if( ($Artifacts -like "all") -or ($Artifacts -like "*DAT*") ){   
        New-Item -ItemType directory -Path ("C:\VolH\Output\DATs") 
        $Users = Get-ChildItem C:\Users\
        foreach ($name in $Users.Name){
            Copy-Item -Path "C:\Users\$name\NTUSER.DAT" -Force -Destination "C:\VolH\Output\DATs\$name-NTUSER.DAT"
            Copy-Item -Path "C:\Users\$name\AppData\Local\Microsoft\Windows\UsrClass.dat" -Force -Destination "C:\VolH\Output\DATs\$name-UsrClass.dat"
        }
        ### Unhide the gathered DAT files
        $h = Get-ChildItem C:\VolH\Output\DATs -Force
        foreach($thing in $h){
            $thing.Attributes = $thing.Attributes -bxor [System.IO.FileAttributes]::Hidden
        }
    }
    ### Gather recent execution
    if( ($Artifacts -like "all") -or ($Artifacts -like "*LNK*") ){
        New-Item -ItemType directory -Path ("C:\VolH\Output\LNKs")
        foreach ($name in $Users.Name){
            foreach($fileName in (Get-ChildItem C:\Users\$name\AppData\Roaming\Microsoft\Windows\Recent).Name){
                Copy-Item -Path "C:\Users\$name\AppData\Roaming\Microsoft\Windows\Recent\$fileName" -Force -Destination "C:\VolH\Output\LNKs\$name-$fileName"
            }
        }
    }
    ### Gather Shimcache and/or stateful info
    if( ($Artifacts -like "all") -or ($Artifacts -like "*shim*") -or ($Artifacts -like "*state*") ){
        New-Item -ItemType directory -Path ("C:\VolH\Output\Other")
        if( ($Artifacts -like "all") -or ($Artifacts -like "*shim*") ){
            reg export "HKLM:\System\CurrentControlSet\Control\Session Manager\AppCompatCache\AppCompatCache" "C:\VolH\Output\Other\shim.reg"
        }
        if( ($Artifacts -like "all") -or ($Artifacts -like "*state*") ){
            netstat -ano > "C:\VolH\Output\Other\netstat.txt"
            tasklist /V > "C:\VolH\Output\Other\tasklist.txt"
        }
    }
    "Done" > "C:\VolH\ArtsGathered.txt"
}

Add-Content -Path $logLocation -Value "Plugins are $Plugins`n"

if($Plugins){
    $command = "C:\VolH\Tools\volatility.exe"
    ### TEMPORARILY CHANGE $env:temp TO BYPASS BLOCKED TEMP FOLDER EXECUTION ###
    Add-Content -Path "$logLocation" -Value "Changing temp environment variables`n"
    $backupTemp = $env:temp
    $env:temp = "C:\VolH\"
    $env:tmp = "C:\VolH\"

    if( ($Plugins -like "*malfind*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "malfind" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*ssdt*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "ssdt" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*cmdline*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "cmdline" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*psscan*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "psscan" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*mutantscan*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "mutantscan" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*dlllist*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "dlllist" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*ldrmodules*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "ldrmodules" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*netscan*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "netscan" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*psxview*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "psxview" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*timers*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "timers" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }

    ### FIX TEMP FOLDER CHANGE ###
    $env:temp = $backupTemp
    $env:tmp = $backupTemp
    Add-Content -Path "$logLocation" -Value "Temp environment variables restored`n"
}

#############################################
### Finalize VolHunter, Record Total Time ###
#############################################

[string]$hash = (Get-FileHash -Algorithm SHA256 C:\VolH\Image\$hostName.bin).Hash
Add-Content -Path "$logLocation" -Value "Memory dump sha256 hash is $hash"

try{
    Move-Item "C:\VolH\Image\*.bin" -Destination "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb"
    $first = Get-RandomDate -Min "01/01/2015 00:00:00.000"
    $second = Get-RandomDate -Min "01/01/2015 00:00:00.000"
    if($first -lt $second){
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").CreationTime=($first)
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastWriteTime=($second)
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastAccessTime=($second)
    }
    else{
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").CreationTime=($second)
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastWriteTime=($first)
        (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastAccessTime=($first)
    }
    Add-Content -Path "Moved bin file to C:\Windows\SoftwareDistribution\DataStore\$hostName.edb" 
}
catch{
    Add-Content -Path $logLocation -Value "$_ hiding & timestomping failed"
}

$GLOBALEND = Get-Date
Add-Content -Path "$logLocation" -Value "TOTAL RUNTIME $($GLOBALEND-$GLOBALSTART) H:M:S.MS`n"
Add-Content -Path "$logLocation" -Value "VolHunter is now complete!`n"
$volDone = "Volatility completed"
Out-File -FilePath "C:\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
