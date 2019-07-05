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
    $ScriptBlock = { 
        Param($cred)
        cd C:\Windows\CCM\CIAgent\VH
        Import-Module .\VolHunter.psm1
        Set-VHEnvironment -DumpMemory $True -Plugins "cmdline" -cred $cred -MaxThreads 50
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
                New-Item -ItemType directory -Path ("C:\Windows\CCM\CIAgent\VH\") | %{$_.Attributes = "hidden"}
                New-Item -ItemType directory -Path ("C:\Windows\CCM\CIAgent\VH\bin\")
                New-Item -ItemType directory -Path ("C:\Windows\CCM\CIAgent\VH\GatheredLogs\")
                New-Item -ItemType directory -Path ("C:\Windows\CCM\CIAgent\VH\JobLogs\")
                New-Item -ItemType directory -Path ("C:\Windows\CCM\CIAgent\VH\VHLogs\")
            }
        } >$null 2>&1

        Write-Host "Sending files and target list $X to $target" -BackgroundColor White -ForegroundColor Black
        Copy-Item -Path ".\targetset$X.txt" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\targetlist.txt"
        $X++
        Copy-Item -Path ".\VolHunter.psm1" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\VolHunter.psm1"
        Copy-Item -Path ".\bin\DumpIt-64.exe" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\bin\DumpIt-64.exe"
        Copy-Item -Path ".\bin\DumpIt-86.exe" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\bin\DumpIt-86.exe"
        Copy-Item -Path ".\bin\volatility.exe" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\bin\volatility.exe"
        Copy-Item -Path ".\bin\VolHunterRemote.ps1" -Destination "\\$target\C$\Windows\CCM\CIAgent\VH\bin\VolHunterRemote.ps1"
        $time = Get-Date
        Write-Host "All items sent to intermediary $target at $time" -BackgroundColor Green -ForegroundColor Black
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
}

if($GatherAll){
    foreach($host in (Get-Content $Intermediaries)){
        Write-Host "Grabbing outputs from intermediary $host" -BackgroundColor White -ForegroundColor Black
        Copy-Item -Path "\\$host\C$\Windows\CCM\CIAgent\VH\GatheredLogs\*" -Destination .\GatheredLogs\
        Copy-Item -Path "\\$host\C$\Windows\CCM\CIAgent\VH\VHLogs\*" -Destination .\VHLogs\
    }
}

if($RemoveInt){
    foreach($inter in (Get-Content $Intermediaries)){
        try{
            Write-Host "Cleaning $inter"
            Invoke-Command -Computer $inter -ScriptBlock {Remove-Item -path C:\Windows\CCM\CIAgent\VH -Recurse -Force} -ErrorAction SilentlyContinue
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
            Get-Content \\$comp\C$\Windows\CCM\CIAgent\VH\OnList.txt | Add-Content -Path .\masteron.txt
        }
        catch{
            Write-Error -Message "$_ RemoveInt failed"
        }
    }
}