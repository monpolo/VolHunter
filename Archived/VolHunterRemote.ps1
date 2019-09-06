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
    try{
        $command = "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe"
        $hn = hostname
        Add-Content -Path $logLocation -Value "Running $plugin plugin`n"
        $start = Get-Date
        if($HR -eq "True"){
            $outFile = $outputDir + $plugin + "-" + $hn + ".txt"
            $timeouted = $null
            $proc = Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin" -RedirectStandardOutput $outFile -PassThru
            $proc | Wait-Process -Timeout 3600 -ErrorAction SilentlyContinue -ErrorVariable timeouted

            if($timeouted){
                $proc | kill
                #remove-item $outFile -Force
                $end = Get-Date
                Add-Content -Path $logLocation -Value "$plugin plugin timed-out in $($end-$start)`n"
                continue
            }
        }
        else{
            $outFile = $outputDir + $plugin + "-" + $hn + ".xlsx"
            $timeouted = $null
            $proc = Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin --output=xlsx --output-file=$outFile" -PassThru
            $proc | Wait-Process -Timeout 3600 -ErrorAction SilentlyContinue -ErrorVariable timeouted

            if($timeouted){
                $proc | kill
                $end = Get-Date
                Add-Content -Path $logLocation -Value "$plugin plugin timed-out in $($end-$start)`n" 
                continue
            }
        }
        $end = Get-Date
        Add-Content -Path $logLocation -Value "$plugin plugin completed in $($end-$start) H:M:S.MS`n" 
    }
    catch{
        Add-Content -Path $logLocation -Value "$_ $plugin failed"
        continue
    }
}

Function Get-RandomDate {
    [cmdletbinding()]

    param([DateTime]$Min,[DateTime]$Max = [DateTime]::Now)
    $randomTicks = Get-Random -Minimum $Min.Ticks -Maximum $Max.Ticks
    New-Object DateTime($randomTicks)
}

$GLOBALSTART = Get-Date

### Static Variables ###
$hostName = hostname
$hostImg = $hostName + ".bin"
$baseDir = "C:\Windows\CCM\Perf\VolH\"
$imageDir = "C:\Windows\CCM\Perf\VolH\Image\"
$outputDir = "C:\Windows\CCM\Perf\VolH\Output\"
$toolDir = "C:\Windows\CCM\Perf\VolH\Tools\"
$imgLocation = "C:\Windows\CCM\Perf\VolH\Image\$hostImg"
$time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"+"T"+"HH:mm:ss.fff"+"Z")
$outer = 0
$inner = 0
$Architecture = 64
$OSVersi = [System.Environment]::OSVersion.Version
$logLocation = "C:\Windows\CCM\Perf\VolH\VHLog-$hostname.txt"

$vhlog = "Starting VolHunter at $time `n"
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
    Add-Content -Path "C:\Windows\CCM\Perf\VolH\VHLog.txt" -Value "Not enough free disk space`n"
    $volDone = "Not enough freespace on C:\ to run`n"
    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
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

Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolProfile.txt" -InputObject $volProfile -Encoding ASCII
Add-Content -Path "$logLocation" -Value "Volatility Profile = $volProfile `n"

if($volProfile -eq "ERROR"){ 
    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\UNRECOGNIZEDPROFILE.txt" -InputObject $volProfile -Enocding ASCII
    $volDone = "VHRemote failed due to unrecognized profile"
    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
    exit
}

###############################
### Run memory dumping tool ###
###############################
Add-Content -Path $logLocation -Value "dumpFlag is $dumpFlag"
if($dumpFlag -eq "True"){
    Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 comae.io"
    $dumpCommand = "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe"
    Add-Content -Path "$logLocation" -Value "Starting memory dump`n"
    $start = Get-Date
    Start-Process -Filepath $dumpCommand -ArgumentList "/Q /N /J /T RAW /OUTPUT $imgLocation" -wait
    $end = Get-Date
    $dumpDone = "DumpIt Completed"
    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\DumpDone.txt" -InputObject $dumpDone -Encoding ASCII
    Get-Content "C:\Windows\System32\drivers\etc\hosts" | Where-Object {$_ -notmatch 'comae'} | Set-Content "C:\Windows\System32\drivers\etc\hosts2"
    Get-Content "C:\Windows\System32\drivers\etc\hosts2" | Set-Content "C:\Windows\System32\drivers\etc\hosts"
    Remove-Item "C:\Windows\System32\drivers\etc\hosts2"
    Add-Content -Path "$logLocation" -Value "Memory dump completed in $($end-$start) H:M:S.MS`n"
}

#####################################
### Gather artifacts as requested ###
#####################################
if( ($Artifacts -like "all") -or ($Artifacts -like "*pf*") -or ($Artifacts -like "*events*") -or ($Artifacts -like "*firewall*") -or ($Artifacts -like "*DAT*") -or ($Artifacts -like "*LNK*") -or ($Artifacts -like "*shim*") -or ($Artifacts -like "*state*") ){
    ### Gather Prefetch
    if( ($Artifacts -like "all") -or ($Artifacts -like "*pf*") ){
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\Prefetch")
        Copy-Item -Path "C:\Windows\Prefetch\*.pf" -Destination "C:\Windows\CCM\Perf\VolH\Output\Prefetch\"
    }
    ### Gather Event Logs
    if( ($Artifacts -like "all") -or ($Artifacts -like "*events*") ){
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\EventLogs")
        Copy-Item -Path "C:\Windows\System32\Winevt\Logs\*" -Destination "C:\Windows\CCM\Perf\VolH\Output\EventLogs\"
    }
    ### Gather Firewall Logs
    if( ($Artifacts -like "all") -or ($Artifacts -like "*firewall*") ){
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\FWLogs")
        Copy-Item -Path "C:\Windows\System32\LogFiles\Firewall\*" -Destination "C:\Windows\CCM\Perf\VolH\Output\FWLogs\"
    }
    ### Gather NTUSER.DATs, won't work for currently logged in users
    if( ($Artifacts -like "all") -or ($Artifacts -like "*DAT*") ){   
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\DATs") 
        $Users = Get-ChildItem C:\Users\
        foreach ($name in $Users.Name){
            Copy-Item -Path "C:\Users\$name\NTUSER.DAT" -Force -Destination "C:\Windows\CCM\Perf\VolH\Output\DATs\$name-NTUSER.DAT"
            Copy-Item -Path "C:\Users\$name\AppData\Local\Microsoft\Windows\UsrClass.dat" -Force -Destination "C:\Windows\CCM\Perf\VolH\Output\DATs\$name-UsrClass.dat"
        }
        ### Unhide the gathered DAT files
        $h = Get-ChildItem C:\Windows\CCM\Perf\VolH\Output\DATs -Force
        foreach($thing in $h){
            $thing.Attributes = $thing.Attributes -bxor [System.IO.FileAttributes]::Hidden
        }
    }
    ### Gather recent execution
    if( ($Artifacts -like "all") -or ($Artifacts -like "*LNK*") ){
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\LNKs")
        foreach ($name in $Users.Name){
            foreach($fileName in (Get-ChildItem C:\Users\$name\AppData\Roaming\Microsoft\Windows\Recent).Name){
                Copy-Item -Path "C:\Users\$name\AppData\Roaming\Microsoft\Windows\Recent\$fileName" -Force -Destination "C:\Windows\CCM\Perf\VolH\Output\LNKs\$name-$fileName"
            }
        }
    }
    ### Gather Shimcache and/or stateful info
    if( ($Artifacts -like "all") -or ($Artifacts -like "*shim*") -or ($Artifacts -like "*state*") ){
        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\Other")
        if( ($Artifacts -like "all") -or ($Artifacts -like "*shim*") ){
            reg export "HKLM:\System\CurrentControlSet\Control\Session Manager\AppCompatCache\AppCompatCache" "C:\Windows\CCM\Perf\VolH\Output\Other\shim.reg"
        }
        if( ($Artifacts -like "all") -or ($Artifacts -like "*state*") ){
            netstat -ano > "C:\Windows\CCM\Perf\VolH\Output\Other\netstat.txt"
            tasklist /V > "C:\Windows\CCM\Perf\VolH\Output\Other\tasklist.txt"
        }
    }
    "Done" > "C:\Windows\CCM\Perf\VolH\ArtsGathered.txt"
}

Add-Content -Path $logLocation -Value "Plugins are $Plugins`n"

if($Plugins){
    $command = "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe"
    ### TEMPORARILY CHANGE $env:temp TO BYPASS BLOCKED TEMP FOLDER EXECUTION ###
    Add-Content -Path "$logLocation" -Value "Changing temp environment variables`n"
    $backupTemp = $env:temp
    $env:temp = "C:\Windows\CCM\Perf\VolH\"
    $env:tmp = "C:\Windows\CCM\Perf\VolH\"

    if( ($Plugins -like "*malfind*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "malfind" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*ssdt*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "ssdt" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    if( ($Plugins -like "*cmdline*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "cmdline" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }
    #if( ($Plugins -like "*psscan*") -or ($Plugins -like "all") ){
    #    Run-Vol -plugin "psscan" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    #}
    #if( ($Plugins -like "*mutantscan*") -or ($Plugins -like "all") ){
    #    Run-Vol -plugin "mutantscan" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    #}
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
    if( ($Plugins -like "*pslist*") -or ($Plugins -like "all") ){
        Run-Vol -plugin "pslist" -HR $HumanReadable -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
    }

    ### FIX TEMP FOLDER CHANGE ###
    $env:temp = $backupTemp
    $env:tmp = $backupTemp
    Add-Content -Path "$logLocation" -Value "Temp environment variables restored`n"
}

#############################################
### Finalize VolHunter, Record Total Time ###
#############################################
if($dumpFlag -eq "True"){
    [string]$hash = (Get-FileHash -Algorithm SHA256 C:\Windows\CCM\Perf\VolH\Image\$hostName.bin).Hash
    Add-Content -Path "$logLocation" -Value "Memory dump sha256 hash is $hash"

    try{
        Move-Item "C:\Windows\CCM\Perf\VolH\Image\*.bin" -Destination "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb" -Force
        Start-Sleep -Seconds 2
        $oldYear = (Get-Date).AddYears(-3)
        $first = Get-RandomDate -Min $oldYear
        $second = Get-RandomDate -Min $oldYear
        if($first -lt $second){
            Add-Content -Path $logLocation -Value "Timestomping FIRST $first SECOND $second"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").CreationTime=($first)
            Add-Content -Path $logLocation -Value "FIRST CREATION"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastWriteTime=($second)
            Add-Content -Path $logLocation -Value "FIRST WRITE"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastAccessTime=($first)
            Add-Content -Path $logLocation -Value "FIRST ACCESS"
        }
        else{
            Add-Content -Path $logLocation -Value "Timestomping SECOND $second FIRST $first"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").CreationTime=($second)
            Add-Content -Path $logLocation -Value "SECOND CREATION"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastWriteTime=($first)
            Add-Content -Path $logLocation -Value "SECOND WRITE"
            (Get-Item "C:\Windows\SoftwareDistribution\DataStore\$hostName.edb").LastAccessTime=($second)
            Add-Content -Path $logLocation -Value "SECOND ACCESS"
        }
        Add-Content -Path $logLocation -Value "Moved bin file to C:\Windows\SoftwareDistribution\DataStore\$hostName.edb" 
    }
    catch{
        Add-Content -Path $logLocation -Value "$_ hiding & timestomping failed"
    }
}

$GLOBALEND = Get-Date
Add-Content -Path "$logLocation" -Value "TOTAL RUNTIME $($GLOBALEND-$GLOBALSTART) H:M:S.MS`n"
Add-Content -Path "$logLocation" -Value "VolHunter is now complete!`n"
$volDone = "Volatility completed"
Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolDone.txt" -InputObject $volDone -Encoding ASCII
