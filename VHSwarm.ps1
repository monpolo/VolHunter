<#
.SYNOPSIS
VHSwarm aims to further "parallelize" VolHunter through using multiple
hosts to run VolHunter against a large target set.

Given a large (100's to 1,000's) target set, split execution up into
multiple equal groups. One host running VHSwarm, sends VolHunter to
[$NumberOfHosts] hosts along with a subset of total targets and
begins execution of VolHunterRemote against that subset.

VHSwarm will take your master target list and split it into equally
sized lists for your intermediary hosts to execute against.

.PARAMETER Intermediaries
An optional parameter, default value of ".\IntermediaryList.txt"
These are the host names you will use to spread the load of VolHunter

.PARAMETER MasterTarget
An optional parameter, default value of ".\targetlist.txt"
Your master list of hosts to run VolHunter against

.PARAMETER RunVH
An optional switch, default FALSE. When you supply this switch,
it will create subset target lists, move files to intermediaries,
and kick off execution on each intermediary

.PARAMETER GatherOutput
An optional switch, default FALSE. When you supply this switch,
it will tell intermediaries to gather output files from their
subset of target hosts

.PARAMETER CleanUp
An optional switch, default FALSE. When you supply this switch,
will instruct intermediaries to remove all VHR files from their
subset of target hosts

.PARAMETER GatherAll
An optional switch, default FALSE. When you supply this switch,
your host will gather all output files from each intermediary

.NOTES
    Author: Michael "FUMBLES" Russell
    Date:   11 February 2019
    Version: 1.0.6
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$Intermediaries = ".\IntermediaryList.txt",
    [Parameter(Mandatory=$False,Position=1)]
        [String]$MasterTarget = ".\targetlist.txt",
    [Parameter(Mandatory=$False,Position=2)]
        [Switch]$RunVH = $False,
    [Parameter(Mandatory=$False,Position=3)]
        [Switch]$GatherOutput = $False,
    [Parameter(Mandatory=$False,Position=4)]
        [Switch]$CleanUp = $False,
    [Parameter(Mandatory=$False,Position=5)]
        [Switch]$GatherAll = $False,
    [Parameter(Mandatory=$True,Position=6)]
        $credName
)

if($RunVH){
    #$cred = Get-Credential $credName
    $ScriptBlock = { 
        Param($cred)
        cd C:\VH
        Import-Module .\VolHunter.psm1
        Set-VHEnvironment -DumpMemory $True -Plugins "all" -cred $cred -MaxThreads 50
        Start-VHInvestigation
    }

    $NumberOfHosts = (Get-Content $Intermediaries | Measure-Object -Line).Lines
    $NewArrays = @{}; $i = 0;  Get-Content $MasterTarget | %{$NewArrays[$i % $NumberOfHosts] += @($_); $i++}; 
    for($i=0;$i -lt $NewArrays.count;$i++){
        Out-File -FilePath ".\targetset$i.txt" -InputObject $NewArrays.Item($i) -append 
    }

    $X = 0
    foreach($target in (Get-Content $Intermediaries)){
        Invoke-Command -ComputerName $target -ScriptBlock{
            if(!(Test-Path -Path "C:\VH\")){
                New-Item -ItemType directory -Path ("C:\VH\") | %{$_.Attributes = "hidden"}
                New-Item -ItemType directory -Path ("C:\VH\bin\")
                New-Item -ItemType directory -Path ("C:\VH\GatheredLogs\")
                New-Item -ItemType directory -Path ("C:\VH\JobLogs\")
                New-Item -ItemType directory -Path ("C:\VH\VHLogs\")
            }
        } >$null 2>&1

        Write-Host "Sending files and target list $X to $target" -BackgroundColor White -ForegroundColor Black
        Copy-Item -Path ".\targetset$X.txt" -Destination "\\$target\C$\VH\targetlist.txt"
        $X++
        Copy-Item -Path ".\VolHunter.psm1" -Destination "\\$target\C$\VH\VolHunter.psm1"
        Copy-Item -Path ".\bin\DumpIt-64.exe" -Destination "\\$target\C$\VH\bin\DumpIt-64.exe"
        Copy-Item -Path ".\bin\DumpIt-86.exe" -Destination "\\$target\C$\VH\bin\DumpIt-86.exe"
        Copy-Item -Path ".\bin\volatility.exe" -Destination "\\$target\C$\VH\bin\volatility.exe"
        Copy-Item -Path ".\bin\VolHunterRemote.ps1" -Destination "\\$target\C$\VH\bin\VolHunterRemote.ps1"
        Write-Host "All items sent to $target" -BackgroundColor Green -ForegroundColor Black
        Invoke-Command -ComputerName $target -ScriptBlock $scriptBlock -ArgumentList $credName 2>$null
    }
}
<# DO THESE WHILE ON THOSE SYSTEMS, OR DO IT FROM YOUR MAIN HOST. DEBUG THIS!
if($GatherOutput){
    $ScriptBlock = { 
        cd C:\VH
        Import-Module .\VolHunter.psm1
        Set-VHEnvironment -cred $cred -MaxThreads 50
        Get-VHOutput
    }

    foreach($target in (Get-Content $Intermediaries)){
        #Invoke-Command -ComputerName $target -InDisconnectedSession -ScriptBlock $ScriptBlock 2>$null
        Invoke-Command -ComputerName $target -ScriptBlock $ScriptBlock -ArgumentList $credName 2>$null
    }
}

if($CleanUp){
    $ScriptBlock = { 
        cd C:\VH
        Import-Module .\VolHunter.psm1
        Set-VHEnvironment -cred $cred -MaxThreads 50
        Remove-VHRemote
    }

    foreach($target in (Get-Content $Intermediaries)){
        Invoke-Command -ComputerName $target -InDisconnectedSession -ScriptBlock $ScriptBlock 2>$null
    }
}
#>
if($GatherAll){
    foreach($host in (Get-Content $Intermediaries)){
        Write-Host "Grabbing outputs from intermediary $host" -BackgroundColor White -ForegroundColor Black
        Copy-Item -Path "\\$host\C$\VH\GatheredLogs\*" -Destination .\GatheredLogs\
        Copy-Item -Path "\\$host\C$\VH\VHLogs\*" -Destination .\VHLogs\
    }
}

#POSSIBLE FIX for double hop. If we pass -Credential $Using:cred to the $credName arg of Set-VHEnvironment, will this work with only 1 auth?
<#
# This works without delegation, passing fresh creds            
# Note $Using:Cred in nested request            
$cred = Get-Credential Contoso\Administrator            
Invoke-Command -ComputerName ServerB -Credential $cred -ScriptBlock {            
    hostname            
    Invoke-Command -ComputerName ServerC -Credential $Using:cred -ScriptBlock {hostname}            
}
#https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/
#https://stackoverflow.com/questions/6239647/using-powershell-credentials-without-being-prompted-for-a-password
#http://web.archive.org/web/20160822030847/http://geekswithblogs.net/Lance/archive/2007/02/16/106518.aspx
#>
