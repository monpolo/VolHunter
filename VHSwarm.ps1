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
    Date:   15 February 2019
    Version: 1.0.7
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
        $credName,
    [Parameter(Mandatory=$False,Position=7)]
        [Switch]$RemoveInt = $False,
    [Parameter(Mandatory=$False,Position=8)]
        [Switch]$GetOnLists = $False,
    [Parameter(Mandatory=$False,Position=9)]
        [Switch]$CheckStatus = $False
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
    
    Remove-Item ".\targetset*.txt"
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
        $time = Get-Date
        Write-Host "All items sent to intermediary $target at $time" -BackgroundColor Green -ForegroundColor Black

        #$s = New-PSSession -ComputerName $target -Credential $credName
        #Invoke-Command -Session $s -AsJob -JobName $target -ScriptBlock $scriptBlock -ArgumentList $credName 2>$null
        Invoke-Command -ComputerName $target -AsJob -JobName $target -ScriptBlock $scriptBlock -ArgumentList $credName 2>$null
    }
    start-sleep 5
    Get-Job | Receive-Job -Keep
}

if($CheckStatus){


    if(@(Get-Job -State running).count -gt 0){
        $x = @(Get-Job -State running).count
        Write-Host "Still running $x jobs on:" -BackgroundColor Yellow -ForegroundColor Black
        foreach($job in Get-Job){
            $Inter = $job.Location
            if($job.State -eq "Running"){
                Write-Host "$Inter"
            }
            Out-File -FilePath .\InterLogs\Inter-$Inter.txt -InputObject $job.ChildJobs.Information
            Out-File -FilePath .\InterLogs\Errors-Inter-$Inter.txt -InputObject $job.ChildJobs.Error
        }
    }
    elseif(@(Get-Job -State running).count -eq 0){
        Write-Host "All jobs completed" -BackgroundColor DarkGreen -ForegroundColor White
        foreach($job in Get-Job){
            $Inter = $job.Location
            Out-File -FilePath .\InterLogs\Inter-$Inter.txt -InputObject $job.ChildJobs.Information
            Out-File -FilePath .\InterLogs\Errors-Inter-$Inter.txt -InputObject $job.ChildJobs.Error
        }
        Get-Job | Remove-Job
        Get-PSSession | Remove-PSSession
    }

    <#
    foreach($job in Get-Job){
        if($job.State -eq "Completed"){
            $Inter = $job.Location
            Write-Host "$Inter is complete" -BackgroundColor DarkGreen -ForegroundColor White
        }
        if($job.HasMoreData){
            $Inter = $job.Location
            #$JobData = Receive-Job -Job $job
            #Receive-Job -Job $job -Keep >> .\Inter-$Inter.txt
            #"JOB DATA IS $JobData for $Inter"
            Out-File -FilePath .\Inter-$Inter.txt -InputObject $job.ChildJobs.Information
            Out-File -FilePath .\Inter-$Inter-Errors.txt -InputObject $job.ChildJobs.Error
            Write-Host "Updated $Inter log"
        }
    }#>
}

if($GatherAll){
    foreach($host in (Get-Content $Intermediaries)){
        Write-Host "Grabbing outputs from intermediary $host" -BackgroundColor White -ForegroundColor Black
        Copy-Item -Path "\\$host\C$\VH\GatheredLogs\*" -Destination .\GatheredLogs\
        Copy-Item -Path "\\$host\C$\VH\VHLogs\*" -Destination .\VHLogs\
    }
}

if($RemoveInt){
    foreach($inter in (Get-Content $Intermediaries)){
        try{
            Write-Host "Cleaning $inter"
            Invoke-Command -Computer $inter -ScriptBlock {Remove-Item -path C:\VH -Recurse -Force} -ErrorAction SilentlyContinue
        }
        catch{
            Write-Error -Message "$_ RemoveInt failed"
        }
    }
}

if($GetOnLists){
    Remove-Item .\masteron.txt -ErrorAction SilentlyContinue
    foreach($comp in (Get-Content $Intermediaries)){
        try{
            Write-Host "Grabbing OnList from $comp"
            Get-Content \\$comp\C$\VH\OnList.txt | Add-Content -Path .\masteron.txt
        }
        catch{
            Write-Error -Message "$_ RemoveInt failed"
        }
    }
}