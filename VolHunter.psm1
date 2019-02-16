Function Convert-VHElastic{
<#
.SYNOPSIS
Function used to modify non "human readable" output from VolHunterRemote (XLSX format) for ingestion into Elastic
Simply adds a column that includes the hostname and changes to CSV format
#>
    foreach($excelFile in (Get-ChildItem .\GatheredLogs\*.xlsx).FullName){
        $csvName = ((($excelFile.Replace("GatheredLogs\","~")).Split("~"))[1]).Replace(".xlsx","")
        Write-It -msg "Processing $csvName" -type Information #PUT ME OUT TO VHLOG
        $Excel = New-Object -ComObject Excel.Application
        $Excel.Visible = $false
        $Excel.DisplayAlerts = $false
        $wb = $Excel.Workbooks.Open($excelFile)
        $wd = (pwd).Path
        foreach($ws in $wb.Worksheets){
            $ws.SaveAs("$wd\GatheredLogs\$csvName-WORKINGFILE.csv",6)
        }
        $Excel.Quit()
    }

    foreach($csvFile in (Get-ChildItem .\GatheredLogs\*.csv).FullName){
        $compName = ((($csvFile.Replace("GatheredLogs\","~")).Replace("-WORKINGFILE.csv","~")).Split("~"))[1]
        $splitter = $compName.IndexOf("-") + 1
        $compName2 = $compName.substring($splitter)
        Import-Csv $csvFile | Select-Object *,@{Name='Hostname';Expression={"$compName2"}} | Export-Csv ".\GatheredLogs\$compName-WORKING2.csv" -NoTypeInformation
        Import-Csv ".\GatheredLogs\$compName-WORKING2.csv" | Select-Object *,@{Name='Investigated';Expression={'false'}} | Export-Csv .\GatheredLogs\$compName.csv -NoTypeInformation
    }
    Remove-Item .\GatheredLogs\*-WORKING*.csv
}

###Not to be exposed by module
Function Copy-File {
    param( [string]$from, [string]$to)
    $ffile = [io.file]::OpenRead($from)
    $tofile = [io.file]::OpenWrite($to)
    Write-Progress `
        -Activity "Copying file" `
        -status ($from.Split("\")|select -last 1) `
        -PercentComplete 0
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew();
        [byte[]]$buff = new-object byte[] (4096*1024)
        [long]$total = [long]$count = 0
        do {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            [int]$pctcomp = ([int]($total/$ffile.Length* 100));
            [int]$secselapsed = [int]($sw.elapsedmilliseconds.ToString())/1000;
            if ( $secselapsed -ne 0 ) {
                [single]$xferrate = (($total/$secselapsed)/1mb);
            } else {
                [single]$xferrate = 0.0
            }
            if ($total % 1mb -eq 0) {
                if($pctcomp -gt 0)`
                    {[int]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed);
                    } else {
                    [int]$secsleft = 0};
                Write-Progress `
                    -Activity ($pctcomp.ToString() + "% Copying file @ " + "{0:n2}" -f $xferrate + " MB/s")`
                    -status ($from.Split("\")|select -last 1) `
                    -PercentComplete $pctcomp `
                    -SecondsRemaining $secsleft;
            }
        } while ($count -gt 0)
    $sw.Stop();
    $sw.Reset();
    }
    finally {
         $ffile.Close();
         $tofile.Close();
        }
}

Function Get-VHCreator{
<#
.SYNOPSIS
Just for fun. Credit where credit is due.
.DESCRIPTION
Just for fun. Credit where credit is due.
.EXAMPLE
PS> Get-VHCreator
#>
    Process{
        Write-Host "                                                                                                                       
                                                                                     .,*//((((//**..                   
                                                                                .,/(((/***,,,,,**/(((/,                
                                                  .,*/((######(//*,.       .,((/**,,.,,,,,,......,...,,/(/             
                                           .,(#%%%%%%%%%#*,,,,,,,*/(#%%((((/*,,,,,,,,*/(##%%%%%#((*,,..,.,/(*          
                                      ./(%%%%%%%%%%%%%%%#*,,,,,,,.,,.,,,,,,,,,,,*(%%%%%%%%%%%%%%%%%%%#(,,..,,(*        
                                    ,(#%%%%%%%%%%%%%%%%%#(***,,,,,,,...,,,,,,*/#%%%%%#%%%%%%###%%%%%#%%(*,...*(,       
                                .*%%%%%%%%%%%%%%%%###(/#%%%%%%%%%%%##/*,,,(#%%###%%%%%%%%%%###%%%%%####%%%*,..,(/.     
                             ,/%%%%%%%%%%%%%#//******(#%%%%%%%%%%%%%%%%%%%%##((**,......,*((#%%%%%##%%%%%%%(*..,((     
                          ./#%%%%%%%%%%#(/**********/%%%%%%%%%%%%%%%%%%#(/.             .*,  .,%&%%%%%%%%%%%#,,.,(*    
                         ,%%%%%%%%%%%(/*************/#%%%%%%%##%%%%%###,            ...,**.    ./#%%###%%%##%*,.,*(.   
                      .#%%%##%%%%%(/****************/#%%%%%%%#%%%###(.       */*,..      .*,.     #%%##%%###%/,..,#*   
                    .#%%%###%%%#/********************#############(,                        .,.   .*#%#######(,...(/.  
                  *#%%%%%%#%%(/****************///(/(#############,                           .,.   *%%######(,...(/.  
                 ,%%#%%%%%%#(***************/####%%#############%#     .*,                     .,,  .%%#####%/,..,(/.  
               /#%%%%%%%%%(***************(#%%%%%%%%##%%%%%%%%%##/   .*###.                         .%%#####%*...,(*   
             ,(%%%%%%%%%(/****************#%%%%%%%%##%%%%%%%#####*   (%####/,                       ,%#####%#,..,(/.   
            ,%%%%%%%%%#******************/##%%%%##%%%%%%%%%%%##%#(#(/,,(##%%#(*.                   ,(%####%(*..,(#.    
           *#%%%%%%%%(/*******************#%%%%%%%%%%%%%%%%%%%%%##%%%%#//**(####((//*,.           ./%###%%(,...(#(     
          (%%%%%%%%#(*********************/(#%%%%%%%%%%%%%%%%%%%#((#%#####/. ,*(((///#%(,        ,%%%##%%(,..,*#*      
        ,(%%%%%%%%/**************************/(%%%%%%%%%%%%%%%%%%%*.,(#%%%%(,        ,(#/.    ./#%%##%%(*,..,(#.       
       /%%%%%%%%#(****************************(%%%%%%%%%%%%%%%%###,   *%%#/*,.    ,*(%%%(,,/(%%%%%##%%(,..,*((,        
      .%%%%%%%%#/****************************/(%%%%#####%%%%%%%%##(/.  /(##%%#####%%%%%%%%%%%#####%%%*,.../##.         
     ,(%%%%%%%#************************/(#####(((((((###%%%%%%%###%%#.   .(#########//##%%%%%%%#%%(*,,.,*#(,           
     #%%%%%%%(***************************/(##(#####%%%%%%%%%%%%#%###/         .%%###/ ,#%%%%%###/,...,*#(,             
   ./%%%%%%%#**********************//((#####(/****(#%%%%%%%%%%%%%##(,    .,*(((%%%%#/  .,(%%####/,,.,##                
   *#%%%%%%#/******************/((#####((/*******/#%#%%%%%%%%%%%%%#(,.,//#%%%%%%%&%#(     #%###%#*,.,#/                
  *#%%%%%%%(************//(#######//************/(%%%%%%%%%%%%%%%%#(/(*#%%%%%%%%%%%##.    ,(#%%%#(,.,#/                
  #%%%%%%%(********//##%##((/********************/%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#(((*     *(#%%%%(,.,#(                
 .%%%%%%%%*****(####(//************************/((#%%%%%%%%%%%%%%%%%%%%%%%%%%%%##/.    *(#%%%%%%%(,,,##                
 ,%%%%%%%#*****///***************************/(%%%%%%%%%%%%%%%%%%%%##%%%%%%%%%#/,     *%%%%%%%%%%(..,##                
 ,%%%%%%%(***********************************#%%%%%%%%%%%%%%%%%###%%%%%%%#(#(/*     .#%%%%%####%#/,.,#(                
 *%%%%%%#(******************,,***************#%%%%%%%%%%%%%%######%%%%%###/.       *#%%%%%%%%###/,,.,#(                
 ,%%%%%%#(*******************************/(##%%%%%%%%%%%#######%%%%%%%%%%%%#/     /#%%%%%%%%%#%(,,..*#*                
 .%%%%%%%#*****************************/(#%%%%%%%%%%%%%%%%###%%%%%%%%%%%%%%%#*..,/%%%%%%%%%%%%%*,..,//.                
 .%%%%%%%#****************************/#%%%%%%%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(,,.,/#.                 
  (%%%%%%%/**************************/(%%%%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%*,...(#/                  
  ,#%%%%%%#/*************************(#%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(*,,.,/(,                   
   *#%%%%%%#/************************/#%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/,,,.*(#,                    
    *%%%%%%%#*************************/%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#/*,,.,*%(,                     
     #%%%%%%%(**********************/#%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#/,,,,,,##.                       
     .(%%%%%%%#******************/###%#/**(##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%(/,,,,,*(#,                         
      .%%%%%%%%(***************(##%%%(/******/(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*,,,,,,/#(,                          
       ,(%%%%%%%%(**********/#%%%#************(%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#(,,,,..,/%#/                             
         .%%%%%%%%#(/*****###(/****************#%%%%%%%%%%%%%%%%%%%%%%%%%%(/*,.,,,,/((/.                               
          .*#%%%%%%%%(/************************/(#%%%%%%%%%%%%%%%%%%%%#*,,....,/(#/,.                                  
            .%%%%%%%%%%/************************(#%%%%%%%%%%%%%%%%%#(*,,,,..,/((/,                                     
              .#%&%%%%%%%%(/*******************(#%%%%%%%%%%%%%%(/*.....,,*##(,.                                        
                 ,#%%%%%%%%%%%%((//************#%%%%%%%%%#(/*,....,,*/((/,                                             
                    ,#%%%%%%%%%%%%%%%%%%%%%%%%%%#//**,,.......,/(((/*                                                  
                      ,#%%%%%%%%%%%%%%%%%%%%%%###/........,*/(#/*,                                                     
                          ,*(%%%%%%%%#############*,*/(((/*,.                                                          
                                ..,**////((((///**,..                                 
         
         The Skulls Present
             VolHunter
             -FUMBLES"
    Return
    }
}

Function Get-VHMemDump{
<#
.SYNOPSIS
Copies memory dump file from target system specified to your host for further analysis.
.DESCRIPTION
Retrieves memory dump from target system.
Will only run against one host at a time.
.EXAMPLE
PS> Get-VHMemDump -Target "Computer3"
.PARAMETER Target
    Mandatory parameter
    [String] Name of host to retrieve memory dump from
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target
    )

    Process{
        try{
            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -PSProvider "FileSystem" -Persist -Root "\\$Target\C$"
            if(Test-Path "$env:shareName\VolH\VolDone.txt"){
                Write-It -msg "Grabbing memory dump from $Target" -type "Information"
                Copy-File -from "$env:shareName\Windows\SoftwareDistribution\DataStore\$Target.edb" -to "$env:VolPath\GatheredLogs\$Target.bin"
            }
            else{
                Write-It -msg "VolHunter not complete on $Target" -type "Warning"
            }
            Remove-PSDrive -Name "$env:shareLetter"
        }
        catch{
            Write-Error -Message "$_ Get-VHMemDump failed"
        }
    }
}

Function Get-VHOutput{
<#
.SYNOPSIS
Gathers VHR output and, if gathered, artifacts to your host
.DESCRIPTION
After validating all systems have completed with Get-VHStatus, run this command to gather the output to your local system.
Will place all VHLog-* files into your VHLogs folder, and volatility output into your GatheredLogs folder
If artifacts were gathered on targets, will copy them back to GatheredLogs\$target\$ArtifactType folders which are created on running this command.
NOTE: If a target system has not completed execution of VHR, this will print a warning message informing you which systems have not finished.
.EXAMPLE
PS> Get-VHOutput
.PARAMETER TargetList
    Default: $env:TargetList
    [String] The path, relative or absolute, to your targetlist file.
    File must contain a list of targets, one per line, with no more than one blank line at the end
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList
    )

    Process{
        foreach($target in get-content $TargetList){    
            try{
                New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -PSProvider "FileSystem" -Persist -Root "\\$target\C$" 1>$null
                if(Test-Path "$env:shareName\VolH\VolDone.txt"){
                    Write-It -msg "Grabbing parsed output from $target`n" -type "Information"
                    Copy-Item -Path "$env:shareName\VolH\Output\*" -Destination $env:VolPath\GatheredLogs\
                    Copy-Item -Path "$env:shareName\VolH\VHLog-*.txt" -Destination $env:VolPath\VHLogs\

                    if(Test-Path "$env:shareName\VolH\ArtsGathered.txt"){
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\Prefetch") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\EventLogs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\FWLogs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\DATs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\Other") -ErrorAction SilentlyContinue >$null

                        Write-It -msg "Grabbing prefetch files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\VolH\Output\Prefetch\*.pf).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\VolH\Output\Prefetch\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\Prefetch\$image"
                            Copy-File -from $src -to $dest
                        }
                
                        Write-It -msg "Grabbing event logs from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\VolH\Output\EventLogs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\VolH\Output\EventLogs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\EventLogs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing firewall logs from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\VolH\Output\FWLogs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\VolH\Output\FWLogs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\FWLogs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing DAT files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\VolH\Output\DATs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\VolH\Output\DATs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\DATs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing other files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\VolH\Output\Other\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\VolH\Output\Other\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\Other\$image"
                            Copy-File -from $src -to $dest
                        }
                    }
                }
                else{
                    Write-It -msg "Volatility not complete on $target" -type "Warning"
                }
                Remove-PSDrive -Name "$env:shareLetter"
            }
            catch{
                Write-Error -Message "$_ Get-VHOutput failed"
            }
        }
    }
}

Function Get-VHStatus{
<#
.SYNOPSIS
Tails last 5 lines of VHLog on one target
.DESCRIPTION
.EXAMPLE
PS> Get-VHStatus -Target [hostname]
.PARAMETER Target
    [String] The name of the system you want to get a status on
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target
    )

    Process{
        try{
            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$Target\C$" 1>$null
            Get-Content -Tail 5 "$env:shareName\VolH\VHLog-$Target.txt"
            Remove-PSDrive -Name "$env:shareLetter"
        }
        catch{
            Write-Error -Message "$_ Get-VHStatus failed"
        }
    }
}

Function Get-VHStatusAll{
<#
.SYNOPSIS
Tails last 5 lines of VHLog on all targets
.DESCRIPTION
.EXAMPLE
PS> Get-VHStatus -Target [hostname]
.PARAMETER Target
    [String] The name of the system you want to get a status on
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList
    )

    Process{
        try{
            foreach($Target in (Get-Content $TargetList)){
                Write-It -msg "Status of $Target" -type "Information"
                New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" 1>$null
                Get-Content -Tail 5 "$env:shareName\VolH\VHLog-$Target.txt" -ErrorAction SilentlyContinue -ErrorVariable errOut
                if($errOut){
                    Write-It -msg "$target has no files" -type "Warning"
                }
                Remove-PSDrive -Name "$env:shareLetter"
            }
        }
        catch{
            Write-Error -Message "$_ Get-VHStatus failed"
        }
    }
}

###Not to be exposed by module
Function Move-VHFiles{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList,
        [Parameter(Mandatory=$True,Position=1)]
            $cred
    )
    
    Process{
        try{
            $volPath = $env:VolPath
            foreach ($target in Get-Content $TargetList){
                Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock{
                    if(!(Test-Path -Path "\\$target\C$\VolH\")){
                        New-Item -ItemType directory -Path ("C:\VolH\") | %{$_.Attributes = "hidden"}
                        New-Item -ItemType directory -Path ("C:\VolH\Image\")
                        New-Item -ItemType directory -Path ("C:\VolH\Output\")
                        New-Item -ItemType directory -Path ("C:\VolH\Tools\")
                    }
                    if($env:Artifacts){
                        New-Item -ItemType directory -Path ("C:\VolH\Artifacts\")
                    }
                } >$null 2>&1
                New-PSDrive -Name "$env:shareLetter" -Credential $cred -Persist -PSProvider "FileSystem" -Root "\\$target\C$"
                if( (Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {[intptr]::size}) -ne 4){
                    Copy-Item -Path $volPath\bin\DumpIt-64.exe -Destination "$env:shareName\VolH\Tools\DumpIt.exe"
                    Copy-Item -Path $volPath\bin\volatility.exe -Destination "$env:shareName\VolH\Tools\volatility.exe"
                }
                else{
                    Copy-Item -Path $volPath\bin\DumpIt-86.exe -Destination "$env:shareName\VolH\Tools\DumpIt.exe"
                    Copy-Item -Path $volPath\bin\volatility.exe -Destination "$env:shareName\VolH\Tools\volatility.exe"
                }
                Copy-Item -Path $volPath\bin\VolHunterRemote.ps1 -Destination "$env:shareName\VolH\Tools\VolHunterRemote.ps1"
                Remove-PSDrive -Name "$env:shareLetter"
                Write-It -msg "`nFolders & tools moved to $target" -type "Information"
            }
        }
        catch{
            Write-Error -Message "$_ Move-VHFiles failed on $target"
            continue
        }
    }
}

Function Move-VHParallel{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$volPath = $env:VolPath,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$MaxThreads = 10,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$TargetList = $env:TargetList,
        [Parameter(Mandatory=$False,Position=3)]
            [Credential]$cred = $global:Credential,
        [Parameter(Mandatory=$False,Position=4)]
            [String]$artifacts = $global:Artifacts
    )

    Process{
        $moveBlock = {
            Param([Credential]$cred,[String]$target,[String]$artifacts,[String]$volPath)
            "`nTarget is $target"
            Invoke-Command -ComputerName $target -Credential $cred -ArgumentList $artifacts -ScriptBlock{
                if(!(Test-Path -Path "C:\VolH\")){
                    New-Item -ItemType directory -Path ("C:\VolH\") | %{$_.Attributes = "hidden"}
                    New-Item -ItemType directory -Path ("C:\VolH\Image\")
                    New-Item -ItemType directory -Path ("C:\VolH\Output\")
                    New-Item -ItemType directory -Path ("C:\VolH\Tools\")
                }
                if($artifacts){
                    New-Item -ItemType Directory -Path ("C:\VolH\Artifacts\")
                }
            } #End Invoke-Command
            $Session = New-PSSession -ComputerName $target -Credential $cred
            if( (Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {[intptr]::size}) -ne 4){
                Copy-Item -Path $volPath\bin\DumpIt-64.exe -Destination "C:\VolH\Tools\DumpIt.exe" -ToSession $Session
            }
            else{
                Copy-Item -Path $volPath\bin\DumpIt-86.exe -Destination "C:\VolH\Tools\DumpIt.exe" -ToSession $Session
            }
            Copy-Item -Path $volPath\bin\volatility.exe -Destination "C:\VolH\Tools\volatility.exe" -ToSession $Session
            Copy-Item -Path $volPath\bin\VolHunterRemote.ps1 -Destination "C:\VolH\Tools\VolHunterRemote.ps1" -ToSession $Session
            Disconnect-PSSession $Session
            Remove-PSSession $Session
        } #End moveBlock

        ###################################################################
        ### NOTE: If copy-item places a lock on a file, use robocopy /B ###
        ###################################################################

        try{
            $XYZ = 0
            Get-Job | Remove-Job
            $volPath = $env:VolPath
            $lineCount = (Get-Content $TargetList | Measure-Object -Line).Lines
            Write-It -msg "Moving files to $lineCount targets - Max of $MaxThreads simultaneously" -type "Information"
            foreach ($target in Get-Content $TargetList){
                While (@(Get-Job -state running).count -ge $MaxThreads){
                    Start-Sleep -Milliseconds 10
                }
                Start-Job -ScriptBlock $moveBlock -ArgumentList $cred, $target, $artifacts, $volPath 1>$null
                $XYZ++
                Write-It -msg "Copying files to $target   # $XYZ / $lineCount" -type "Other"
            }
            Write-It -msg "All jobs started. Waiting for them to finish." -type "Information"
            $lastX = $MaxThreads
            While (@(Get-Job -State running).count -gt 0){
                $x = @(Get-Job -State running).count
                if($lastX -ne $x){
                    Write-It -msg "Still copying to $x systems" -type "Information"
                    $lastX = $x
                }
                Start-Sleep 1
            }
            foreach($job in Get-Job){
                $info = (Receive-Job -Id ($job.Id))
                [string]$jobOut = $info | Select-String -Pattern "Target is "
                $filename = $jobOut.Replace("Target is ","")
                $filename = $filename.Replace("`n","")
                $jobPath = ".\JobLogs\" + $filename + "-" + $job.Id + ".txt"
                Out-File -FilePath "$jobPath" -InputObject $info -Encoding ASCII 
            }
            Write-It -msg "All copies finished. Cleaning up." -type "Information"
            Get-Job | Remove-Job
        }
        catch{
            Write-Error -Message "$_ Move-VHParallel failed"
        }
    }
    End{

    }
}

Function Remove-VHIndices{
<#
.SYNOPSIS
Removes all VolHunter entries from Elastic
.DESCRIPTION
Will delete each VolHunter related index from your Elastic stack.
Be sure you do not have any other relevant data in those indices prior to running this command.
.EXAMPLE
PS> Remove-VHIndices
.PARAMETER ElasticIP
    Default: $env:ElasticIP
    [String] IP address of your Elastic ingest node
.PARAMETER ElasticPort
    Default: $env:ElasticPort
    [Int] Listening port of your Elastic ingest node
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$ElasticIP = $env:ElasticIP,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$ElasticPort = $env:ElasticPort
    )

    Process{
        try{
            $URI = $ElasticIP + ":" + $ElasticPort + "/malfind"
            curl -Method DELETE $URI >$null
            Write-It -msg "Malfind index cleared" -type "Information"

            $URI = $ElasticIP + ":" + $ElasticPort + "/psscan"
            curl -Method DELETE $URI >$null
            Write-It -msg "PSScan index cleared" -type "Information"

            $URI = $ElasticIP + ":" + $ElasticPort + "/ssdt"
            curl -Method DELETE $URI >$null
            Write-It -msg "SSDT index cleared" -type "Information"

            $URI = $ElasticIP + ":" + $ElasticPort + "/cmdline"
            curl -Method DELETE $URI >$null
            Write-It -msg "CMDLine index cleared" -type "Information"

            $URI = $ElasticIP + ":" + $ElasticPort + "/mutantscan"
            curl -Method DELETE $URI >$null
            Write-It -msg "MutantScan index cleared" -type "Information"
        }
        catch{
            Write-Error -Message "$_ Remove-VHIndices failed"
        }
    }
}

Function Remove-VHRemote{
<#
.SYNOPSIS
    Remove all VolHunter related artifacts from targeted hosts
.DESCRIPTION
    Calls Run-VHRemote to delete files and folder structure related to VolHunter from target hosts.
    Will run against $env:MaxThreads simultaneously if no -MaxThreads is provided.
.EXAMPLE
    PS> Remove-VHRemote -TargetList .\path\to\targets.txt -MaxThreads 25
    Will delete VolHunter from all systems listed in targets.txt, 25 simultaneously
.PARAMETER TargetList
    Takes input file of hosts you want to remove VolHunter from
    Each host must be on its own line with no more than 1 blank line at the end of the file
    Defaults to $env:TargetList
.PARAMETER MaxThreads
    Integer value for the max simultaneous targets you wish to interact with
    Defaults to $env:MaxThreads
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$MaxThreads = $env:MaxThreads
    )

    Process{
        $cleanBlock = {
            Param([string]$target, [string]$DumpMem, [string]$volPath, [string]$Plugins, [string]$HumanReadable, [string]$Artifacts, $cred)
            "`nTarget is $target"
            Invoke-Command -Computer $target -Credential $cred -ScriptBlock {Remove-Item -path C:\VolH -Recurse -Force}
            "`nFiles and folders deleted`n"
        }
        Run-VHRemote -block $cleanBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
    }
}

Function Remove-VHMemDump{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$MaxThreads = $env:MaxThreads
    )

    Process{
        $cleanBlock = {
            Param([string]$target, [string]$DumpMem, [string]$volPath, [string]$Plugins, [string]$HumanReadable, [string]$Artifacts, $cred)
            "`nTarget is $target"
            Invoke-Command -Computer $target -Credential $cred -ScriptBlock {$hostname = hostname; Remove-Item -path "C:\Windows\SoftwareDistribution\DataStore\$hostname.edb" -Force}
            "`nMemDump deleted`n"
        }
        Run-VHRemote -block $cleanBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
    }
}

###Not to be exposed by module
Function Run-VHRemote{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [ScriptBlock]$block = $null,
        [Parameter(Mandatory=$False,Position=1)]
            [String]$MaxThreads = $env:MaxThreads,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$TargetList = $env:TargetList,
        [Parameter(Mandatory=$False,Position=3)]
            $cred = $global:Credential
    )

    Process{
        try{
            $XYZ = 0
            Get-Job | Remove-Job
            $volPath = $env:VolPath
            $lineCount = (Get-Content $TargetList | Measure-Object -Line).Lines
            Write-It -msg "Running commands against $lineCount targets - Max of $MaxThreads simultaneously" -type "Information"
            foreach ($target in Get-Content $TargetList){
                While (@(Get-Job -state running).count -ge $MaxThreads){
                    Start-Sleep -Milliseconds 10
                }
                Start-Job -ScriptBlock $block -ArgumentList $target, $env:DumpMemory, $env:VolPath, $env:Plugins, $env:HumanReadable, $env:Artifacts, $cred 1>$null
                $XYZ++
                Write-It -msg "Starting job against $target # $XYZ / $lineCount" -type "Other"
            }
            Write-It -msg "All jobs started. Waiting for them to finish." -type "Information"
            $lastX = $MaxThreads
            While (@(Get-Job -State running).count -gt 0){
                $x = @(Get-Job -State running).count
                if($lastX -ne $x){
                    Write-It -msg "Still running $x jobs" -type "Information"
                    $lastX = $x
                }
                Start-Sleep 1
            }
            foreach($job in Get-Job){
                $info = (Receive-Job -Id ($job.Id))
                [string]$jobOut = $info | Select-String -Pattern "Target is "
                $filename = $jobOut.Replace("Target is ","")
                $filename = $filename.Replace("`n","")
                $jobPath = ".\JobLogs\" + $filename + "-" + $job.Id + ".txt"
                Out-File -FilePath "$jobPath" -InputObject $info -Encoding ASCII 
            }
            Write-It -msg "All jobs finished. Cleaning up." -type "Information"
            Get-Job | Remove-Job
        }
        catch{
            Write-Error -Message "$_ Run-VHRemote failed"
        }
    }
    End{

    }
}

Function Send-VHResults{
<#
.SYNOPSIS
Puts VHR output into Elastic
.DESCRIPTION
$env:HumanReadable must have been set to $False when executing Run-VHInvestigation
Will then post each file in GatheredLogs to $ElasticIP:$ElasticPort/_bulk
NOTE: After successfully pushing a file into Elastic, this function will delete that file from your host to avoid duplicate entries in Elastic.
.EXAMPLE
PS> Send-VHResults
.PARAMETER ElasticIP
    Default: $env:ElasticIP
    [String] IP address of your Elastic ingest node
.PARAMETER ElasticPort
    Default: $env:ElasticPort
    [Int] Listening port of your Elastic ingest node
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$ElasticIP = $env:ElasticIP,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$ElasticPort = $env:ElasticPort
    )

    Process{
        try{
            $testURI = $ElasticIP + ":" + $ElasticPort
            if( !((curl -Method GET $testURI) -like "*tagline*") ){ throw 'Not PSv5' }
            $URI = $ElasticIP + ":" + $ElasticPort + "/" + '_bulk'
            $files = Get-ChildItem $env:VolPath\GatheredLogs\*.txt
            foreach($file in $files) {
                curl -Method POST $URI -ContentType: application/json -InFile $file >$null 2>&1
                Write-It -msg "Shipped $file to Elastic" -type "Success"
                Remove-Item -path $file -force
            }
        }
        catch{
            Write-Error "You're not running PSv5, you can't curl"
        }
    }
}

Function Set-VHInvestigated{
<#
.SYNOPSIS
Removes items from Kibana dashboards
.DESCRIPTION
Sets the "Investigated" flag for each input item in Elastic so that it no longer shows in visualizations
.EXAMPLE
PS> Set-VHInvestigated -Investigated .\path\to\list.txt
Reads in list of Elastic entries that are no longer items of interest
.PARAMETER Investigated
    [String] File should consist of list of items that have been deemed false positives
    Format for file is one entry per line as follows
    [plugin]:[_id value]
#>
    [CmdletBinding()]
    Param(
        [ValidateScript({Test-Path $_})]
            [String]$Investigated = $env:Investigated,
        [Parameter(Mandatory=$False)]
            [String]$ElasticIP = $env:ElasticIP,
        [Parameter(Mandatory=$False)]
            [Int]$ElasticPort = $env:ElasticPort
    )
    Process{
        foreach ($itemsCleared in Get-Content $Investigated){
            try{
                $clearedSplit = $itemsCleared.split(":")
                $URI = $ElasticIP + ":" + $ElasticPort + "/" + $clearedSplit[0] + "/doc/" + $clearedSplit[1] + "/_update?pretty"
                curl -Method POST $URI -ContentType "application/json" -Body '{"doc": { "investigated": "true" }}' >$null
                $message = "Cleared index " + $clearedSplit[0] + " item " + $clearedSplit[1]
                Write-It -msg $message -type "Success"
            }
            catch{
                Write-Error -Message "$_ failed on $clearedSplit[1]"
            }
        }
    }
}

Function Set-VHEnvironment{
<#
.SYNOPSIS
Sets environment variables necessary for proper execution. Must be ran prior to any investigations.
.DESCRIPTION
VolHunter module relies upon local environment variables to simplify command execution. Though each cmdlet allows for custom input to each parameter, they default to the related environment variables that are set by this command.
.EXAMPLE
PS> Set-VHEnvironment -ElasticIP "10.10.10.1" -TargetList = ".\path\to\targetlist.txt"
Sets environment variables, each with a default value listed in the parameters section unless otherwise defined.
.PARAMETER ElasticIP
    Default: "192.168.35.133"
    [String] IP address of your Elastic ingest node
.PARAMETER ElasticPort
    Default: 9200
    [Int] Listening port of your Elastic ingest node. Default installs listen on 9200
.PARAMETER TargetList
    Default: ".\targetlist.txt"
    [String] The path, relative or absolute, to your targetlist file.
    File must contain a list of targets, one per line, with no more than one blank line at the end
.PARAMETER Investigated
    Default: ".\inv.txt"
    [String] The path, relative or absolute, to your investigated file.
    File must contain a list of Elastic indices and entries, one per line, with no more than one blank line at the end.
    Format is:   [plugin]:[_id value]
.PARAMETER MaxThreads
    Default: 10
    [Int] Number of simultaneous connections to run VolHunter against. All execution is handled on remote end after passing files.
    Recommend testing with lightweight commands when determining safe max. Testing has shown 75+ to work without issue.
.PARAMETER Plugins
    Default: "all"
    [String] The list of supported plugins to run against remote images. "all" will run all supported plugins.
    If using multiple, but not all, list each plugin separated by /
    EXAMPLE: cmdline/malfind/ssdt
    Supported plugins:  cmdline
                        malfind
                        mutantscan
                        psscan
                        ssdt
                        apihooks
                        dlllist
                        ldrmodules
                        netscan
                        psxview
.PARAMETER HumanReadable
    Default: $False
    [Switch] Instructs VolHunterRemote whether or not output should be json format (for Elastic ingestion) or human readable for operator analysis.
.PARAMETER Artifacts
    Default: "none"
    [String] Instructs VolHunterRemote which artifact files to gather, if any.
    If using multiple, but not all, list each artifact separated by /
    EXAMPLE: fw/pf/DAT
    Supported artifact files:   pf   (Prefetch files)
                                firewall   (Firewall logs)
                                events (Event logs)
                                DAT (ntuser.dat and usrclass.dat for each non-logged in user)
                                LNK (Gathers .LNK files, recently accessed file links)
                                shim (Exports appcompatcache registry keys)
                                state (Captures tasklist and netstat)
.PARAMETER DumpMemory
    Default: $False
    [Switch] Instructs VolHunterRemote whether or not to create a memory dump
.PARAMETER VolPath
    Default: (Get-Location).Path
    [String] The path VolHunter should reference when moving files to and from targets. If you plan to run module functions outside of your VolHunter folder, this should be explicitly set to avoid incorrect references.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$ElasticIp = "192.168.35.133",
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$ElasticPort = 9200,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$TargetList=".\targetlist.txt",
        [Parameter(Mandatory=$False,Position=3)]
            [String]$Investigated = ".\inv.txt",
        [Parameter(Mandatory=$False,Position=4)]
            [Int]$MaxThreads = 10,
        [Parameter(Mandatory=$False,Position=5)]
            [String]$Plugins = $null,
        [Parameter(Mandatory=$False,Position=6)]
            [Switch]$HumanReadable = $False,
        [Parameter(Mandatory=$False,Position=7)]
            [String]$Artifacts = "none",
        [Parameter(Mandatory=$False,Position=8)]
            [Switch]$DumpMemory = $False,
        [Parameter(Mandatory=$False,Position=9)]
            [String]$VolPath = (Get-Location).Path,
        [Parameter(Mandatory=$True,Position=10)]
            [String]$credName
    )
    Process{
        try{
            $env:ElasticIP = $ElasticIp
            $env:ElasticPort = $ElasticPort
            $env:TargetList = $TargetList
            $env:Investigated = $Investigated
            $env:MaxThreads = $MaxThreads
            $env:Plugins = $Plugins
            $env:HumanReadable = $HumanReadable
            $env:Artifacts = $Artifacts
            $env:DumpMemory = $DumpMemory
            $env:VolPath = $VolPath
            $env:OnList = ".\OnList.txt"
            $env:OffList = ".\OffList.txt"
            $global:Credential = Get-Credential $credName
            $env:shareLetter = Test-VHShareName
            $env:shareName = $env:shareLetter + ":"
        }
        catch{
            Write-Error -Message "$_ Set-VHEnvironment failed"
        }
    }
}

Function Start-VHInvestigation{
<#
.SYNOPSIS
Begins the investigation against targeted hosts.
.DESCRIPTION
Starts execution of VolHunter, will warn you if any targets aren't responding to ping, move necessary files, then start VolHunterRemote.
.EXAMPLE
PS> Run-VHInvestigation -MaxThreads 30
Begins VolHunter with default parameter values, set in environment variables, and explicitly allows 30 simultaneous connections.
.PARAMETER TargetList
    Default: $env:TargetList
    [String] The path, relative or absolute, to your targetlist file.
    File must contain a list of targets, one per line, with no more than one blank line at the end
.PARAMETER MaxThreads
    Default: $env:MaxThreads
    [Int] Number of simultaneous connections to run VolHunter against. All execution is handled on remote end after passing files.
    Recommend testing with lightweight commands when determining safe max. Testing has shown 75+ to work without issue.
.PARAMETER HumanReadable
    Default: $env:HumanReadable
    [String] Instructs VolHunterRemote whether or not output should be json format (for Elastic ingestion) or human readable for operator analysis.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList,
        [Parameter(Mandatory=$False,Position=1)]
            [String]$MaxThreads = $env:MaxThreads,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$HumanReadable = $env:HumanReadable
    )

    Process{
        try{
            $cred = $global:Credential
            $OnList = $env:OnList
            $numFailed = Test-VHConnection -TargetList $TargetList
            $runBlock = {
                Param([string]$target, [string]$DumpMem, [string]$volPath, [string]$Plugins, [string]$HumanReadable, [string]$Artifacts, $cred)
                try{
                    "`nTarget is $target"
                    "`nPlugins are $Plugins"
                    "`nDump is $DumpMem"
                    "`nAttempting to run on $target via Invoke-Command -InDisconnectedSession`n"
                    "`n$target MUST be running PSv3 or greater!`n"
                    $scriptBlock = {
                        Param([string]$dump,[string]$plugin,[string]$human,[string]$arts)
                        Start-Process powershell.exe -ArgumentList "-c C:\VolH\Tools\VolHunterRemote.ps1 $dump $plugin $human $arts"
                    }
                    Invoke-Command -ComputerName $target -Credential $cred -InDisconnectedSession -ScriptBlock $scriptBlock -ArgumentList $DumpMem,$Plugins,$HumanReadable,$Artifacts -ErrorVariable results 2>$null
                    if($results -like "*Disconnected sessions are supported only*"){
                        throw 'PS less than v3'
                    }
                    else{ "`nStarting VolHunter on $target via Invoke-Command -InDisconnectedSession`n" }
                }
                catch{
                    "`nTarget running < PSv3, trying WMIC`n"
                    Get-WmiObject -List -Class Win32_OperatingSystem -Computer $target -ErrorVariable results 1>$null 2>$null
                    if($results -like "*Could not get*"){
                        "`nWMIC is NOT enabled on $target `n"
                        return
                    }
                    else{
                        "`nWMIC enabled on $target `n"
                        "`nStarting VolHunter on $target via WMIC`n"
                        $targIP = [Net.Dns]::GetHostAddresses("$target") | select-object IPAddressToString -expandproperty IPAddressToString
                        WMIC /node:"$targIP" process call create "powershell.exe -c C:\VolH\Tools\VolHunterRemote.ps1 -dumpFlag $DumpMem $Plugins $HumanReadable $Artifacts" 2>$null
                    }
                }
            } #End $runBlock
            Move-VHParallel -volPath $env:VolPath -TargetList $TargetList -cred $global:Credential -artifacts $env:Artifacts
            #Move-VHFiles -TargetList $OnList -cred $cred -ErrorAction Continue
            Run-VHRemote -block $runBlock -MaxThreads $MaxThreads -TargetList $OnList -Cred $cred -ErrorAction Continue
        }
        catch{
            Write-Error -Message "$_ Run-VHRemote failed"
        }
    }
}

###Returns number of targets not responding to ICMP
Function Test-VHConnection{
<#
.SYNOPSIS
Informs you if target system(s) are not communicating, possibly offline.
.DESCRIPTION
Sends a small ICMP ping packet to each listed target, informs you which systems do not respond.
.EXAMPLE
PS> Test-VHConnection -TargetList ".\path\to\targets.txt"
.PARAMETER TargetList
    Default: $env:TargetList
    [String] The path, relative or absolute, to your targetlist file.
    File must contain a list of targets, one per line, with no more than one blank line at the end
.OUTPUTS [Int] Number of systems that did not respond.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList
    )

    Begin{
        $failPing = 0
    }
    Process{
        if((Test-Path -Path ".\OnList.txt")){Remove-Item -Path ".\OnList.txt"}
        if((Test-Path -Path ".\OffList.txt")){Remove-Item -Path ".\OffList.txt"}
        
        foreach ($target in Get-Content $TargetList){
            try{
                if(Test-Connection -ComputerName $target -BufferSize 16 -Count 1 -Quiet){
                    Out-File -FilePath ".\OnList.txt" -InputObject $target -Append
                    continue
                }
                else{
                    Out-File -FilePath ".\OffList.txt" -InputObject $target -Append
                    Write-It -msg "$target not responding to ICMP" -type "Warning"
                    $failPing += 1
                }
            }
            catch{
                Write-Error -Message "$_ Test-VHConnection failed"
            }
        }
        return $failPing
    }
}

Function Test-VHShareName{
    $shareList = net share
    for($test = 0; $test -lt 26; $test++){
        $testChar = [char](65 + $test)
        [string]$testCharString = "*" + $testChar + ":\*"
        if(!($shareList -like "$testCharString")){
            return "$testChar"
        }
    }
}

Function Watch-VHStatus{
<#
.SYNOPSIS
Informs you which target systems have completed running VolHunterRemote
.DESCRIPTION
Reads in list of targets, waits 2 seconds, validates the existence of \\$target\C$\VolH\VHLog* to ensure VHR started properly.
Then every 30 seconds will search for \\$target\C$\VolH\VolDone.txt to validate execution of VHR completed.
NOTE: Will not recheck systems once they have completed, success or failure.
Upon final target finishing, will report how many successes and failures occurred.
.EXAMPLE
PS> Watch-VHStatus -TargetList ".\path\to\targets.txt"
.PARAMETER TargetList
    Default: $env:TargetList
    [String] The path, relative or absolute, to your targetlist file.
    File must contain a list of targets, one per line, with no more than one blank line at the end
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList
    )

    Process{
        try{
            $notDone = $True
            $index = 0
            $targetLength = (Get-Content $TargetList | Measure-Object -Line).Lines
            $array = @()
            $doneCount = 0
            Write-It -msg "Waiting for $targetLength targets to finish. Will notify you when they complete, checking every 30 seconds." -type "Information"
            Start-Sleep 2
            while($index -lt $targetLength){
                $array += @($False)
                $index++
            }
            $index = 0
            $firstRun = 0
            $numFailed = 0
            while($notDone){
                foreach($target in get-content $TargetList){
                    if( !($array[$index]) ){
                        #If first time thru, check if VHLog exists, otherwise VHR failed
                        if($firstRun -lt $targetLength){
                            $firstRun += 1
                            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" 1>$null
                            if(!(Test-Path -Path "$env:shareName\VolH\VHLog*")){
                            Write-It -msg "FAILURE: $target has failed to start VolHunterRemote" -type "Error"
                                $array[$index] = $True
                                $doneCount++
                                $numFailed += 1
                            }
                            else{
                                Write-It -msg "SUCCESS: $target started VolHunterRemote" -type "Success"
                            }
                            Remove-PSDrive -Name "$env:shareLetter"
                        }
                        New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" 1>$null
                        if(Test-Path "$env:shareName\VolH\VolDone.txt"){
                            $date = Get-Date
                            Write-It -msg "$target completed $date" -type "Other"
                            $array[$index] = $True
                            $doneCount++
                            Write-It -msg "$doneCount of $targetLength targets complete." -type "Information"
                        }
                        Remove-PSDrive -Name "$env:shareLetter"
                    }
                    $index++
                }
                $index = 0
                if($doneCount -eq $targetLength){
                    $notDone = $False
                    continue
                }
                start-sleep 30
            }
            Write-It -msg "All $targetLength targets completed" -type "Success"
            if($numFailed -gt 0){
                Write-It -msg "$numFailed target failed to start VHR, check your output" -type "Error"
            }
        }
        catch{
            Write-Error -Message "$_ Get-VHStatus failed"
        }
    }
}

###Not to be exposed by module
Function Write-It{
<#
.SYNOPSIS
Internal function used to template Write-Host formats
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$msg,
        [Parameter(Mandatory=$True,Position=0)]
            [String]$type
    )

    Process{
        try{
            switch ($type){
                {$_ -like "Information"} { $back = "White"; $fore = "Black"}
                {$_ -like "Warning"} { $back = "Yellow"; $fore = "Red"}
                {$_ -like "Error"} { $back = "Red"; $fore = "White"}
                {$_ -like "Success"} { $back = "DarkGreen"; $fore = "White"} 
                default { Write-Host $msg; return }
            }
            Write-Host $msg -ForegroundColor $fore -BackgroundColor $back
        }
        catch{
            Write-Error -Message "$_ Write-It failed... I'm not sure how you managed this."
        }
    }
}

Export-ModuleMember -Function Get-*
Export-ModuleMember -Function Remove-*
Export-ModuleMember -Function Set-*
Export-ModuleMember -Function Convert-VHElastic
Export-ModuleMember -Function Start-VHInvestigation
Export-ModuleMember -Function Send-VHResults
Export-ModuleMember -Function Test-VHConnection
Export-ModuleMember -Function Test-VHShareName
Export-ModuleMember -Function Watch-VHStatus
