<#
.HELP
Version # 1.2
#>
Function Convert-VHElastic{
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
        Import-Csv $csvFile | Select-Object *,@{Name='Hostname';Expression={"$compName2"}},@{Name='Investigated';Expression={'false'}} | Export-Csv ".\GatheredLogs\$compName.csv" -NoTypeInformation
    }
    Remove-Item .\GatheredLogs\*-WORKING*.csv
}

Function Format-VHReport{
    try{
        $path = (pwd).Path
        $reportName = Read-Host -Prompt "Enter report name to run:"
        $fullpath = $path + "\$reportName.xlsx"

        $excelFile = $fullpath
        $Excel = New-Object -ComObject Excel.Application
        $Excel.Visible = $false
        $Excel.DisplayAlerts = $false
        $wb = $Excel.Workbooks.Open($excelFile)
        [int]$i = 2
        $bob = ($wb.Sheets.Item("Sheet1").Cells.Item($i,1).Text)

        while($bob -notlike $null){
            $bob = ($wb.Sheets.Item("Sheet1").Cells.Item($i,1).Text)

            #malfind
            if((test-path "$path\GatheredLogs\malfind-$bob.xlsx") -and ((get-item "$path\GatheredLogs\malfind-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,2).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\malfind-$bob.xlsx") -and ((get-item "$path\GatheredLogs\malfind-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,2).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,2).Interior.ColorIndex = 3
            }

            #ssdt
            if((test-path "$path\GatheredLogs\ssdt-$bob.xlsx") -and ((get-item "$path\GatheredLogs\ssdt-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,3).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\ssdt-$bob.xlsx") -and ((get-item "$path\GatheredLogs\ssdt-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,3).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,3).Interior.ColorIndex = 3
            }

            #cmdline
            if((test-path "$path\GatheredLogs\cmdline-$bob.xlsx") -and ((get-item "$path\GatheredLogs\cmdline-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,4).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\cmdline-$bob.xlsx") -and ((get-item "$path\GatheredLogs\cmdline-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,4).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,4).Interior.ColorIndex = 3
            }

            #dlllist
            if((test-path "$path\GatheredLogs\dlllist-$bob.xlsx") -and ((get-item "$path\GatheredLogs\dlllist-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,5).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\dlllist-$bob.xlsx") -and ((get-item "$path\GatheredLogs\dlllist-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,5).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,5).Interior.ColorIndex = 3
            }

            #ldrmodules
            if((test-path "$path\GatheredLogs\ldrmodules-$bob.xlsx") -and ((get-item "$path\GatheredLogs\ldrmodules-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,6).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\ldrmodules-$bob.xlsx") -and ((get-item "$path\GatheredLogs\ldrmodules-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,6).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,6).Interior.ColorIndex = 3
            }

            #netscan
            if((test-path "$path\GatheredLogs\netscan-$bob.xlsx") -and ((get-item "$path\GatheredLogs\netscan-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,7).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\netscan-$bob.xlsx") -and ((get-item "$path\GatheredLogs\netscan-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,7).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,7).Interior.ColorIndex = 3
            }

            #psxview
            if((test-path "$path\GatheredLogs\psxview-$bob.xlsx") -and ((get-item "$path\GatheredLogs\psxview-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,8).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\psxview-$bob.xlsx") -and ((get-item "$path\GatheredLogs\psxview-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,8).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,8).Interior.ColorIndex = 3
            }

            #timers
            if((test-path "$path\GatheredLogs\timers-$bob.xlsx") -and ((get-item "$path\GatheredLogs\timers-$bob.xlsx").length -gt 0)){
                $wb.worksheets.Item(1).Cells.Item($i,9).Interior.ColorIndex = 4
            }
            elseif((test-path "$path\GatheredLogs\timers-$bob.xlsx") -and ((get-item "$path\GatheredLogs\timers-$bob.xlsx").length -eq 0)){
                $wb.worksheets.Item(1).Cells.Item($i,9).Interior.ColorIndex = 6
            }
            else{
                $wb.worksheets.Item(1).Cells.Item($i,9).Interior.ColorIndex = 3
            }
    
            $bob
            $bob = ($wb.Sheets.Item("Sheet1").Cells.Item(($i + 1),1).Text)
            if($bob -like $null){ break}
            $i++
        }#>

        $wb.SaveAs("$fullpath")
        $wb.Close()
        $Excel.Quit()
    }
    catch{
        Write-Error -Message "$_ Format-VHReport failed"
    }
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
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target
    )

    Process{
        try{
            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -PSProvider "FileSystem" -Persist -Root "\\$Target\C$"
            if(Test-Path "$env:shareName\Windows\CCM\Perf\VolH\VolDone.txt"){
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
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList
    )

    Process{
        $lineCount = (Get-Content $TargetList | Measure-Object -Line).Lines
        $currLine = 0
        foreach($target in get-content $TargetList){    
            try{
                $currLine++
                if(!(Test-Connection -ComputerName $target -BufferSize 16 -Count 1 -Quiet)){
                    Write-It -msg "$target appears offline" -type "Warning"
                    continue
                }
                New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -PSProvider "FileSystem" -Persist -Root "\\$target\C$" 1>$null
                if(Test-Path "$env:shareName\Windows\CCM\Perf\VolH\VolDone.txt"){
                    Write-It -msg "Grabbing parsed output from $target # $currLine / $lineCount`n" -type "Information"
                    Copy-Item -Path "$env:shareName\Windows\CCM\Perf\VolH\Output\*" -Destination $env:VolPath\GatheredLogs\
                    Copy-Item -Path "$env:shareName\Windows\CCM\Perf\VolH\VHLog-*.txt" -Destination $env:VolPath\VHLogs\

                    if(Test-Path "$env:shareName\Windows\CCM\Perf\VolH\ArtsGathered.txt"){
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\Prefetch") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\EventLogs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\FWLogs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\DATs") -ErrorAction SilentlyContinue >$null
                        New-Item -ItemType directory -Path ("$env:VolPath\GatheredLogs\$target\Other") -ErrorAction SilentlyContinue >$null

                        Write-It -msg "Grabbing prefetch files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\Windows\CCM\Perf\VolH\Output\Prefetch\*.pf).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\Windows\CCM\Perf\VolH\Output\Prefetch\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\Prefetch\$image"
                            Copy-File -from $src -to $dest
                        }
                
                        Write-It -msg "Grabbing event logs from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\Windows\CCM\Perf\VolH\Output\EventLogs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\Windows\CCM\Perf\VolH\Output\EventLogs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\EventLogs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing firewall logs from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\Windows\CCM\Perf\VolH\Output\FWLogs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\Windows\CCM\Perf\VolH\Output\FWLogs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\FWLogs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing DAT files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\Windows\CCM\Perf\VolH\Output\DATs\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\Windows\CCM\Perf\VolH\Output\DATs\$image"
                            $dest = "$env:VolPath\GatheredLogs\$target\DATs\$image"
                            Copy-File -from $src -to $dest
                        }

                        Write-It -msg "Grabbing other files from $target`n" -type "Information"
                        $files = (Get-ChildItem $env:shareName\Windows\CCM\Perf\VolH\Output\Other\).Name
                        foreach($image in $files){    
                            $src = "$env:shareName\Windows\CCM\Perf\VolH\Output\Other\$image"
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
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target
    )

    Process{
        try{
            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$Target\C$" 2>$null
            Get-Content -Tail 5 "$env:shareName\Windows\CCM\Perf\VolH\VHLog-$Target.txt"
            Remove-PSDrive -Name "$env:shareLetter"
        }
        catch{
            Write-Error -Message "$_ Get-VHStatus failed"
        }
    }
}

Function Get-VHStatusAll{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList
    )

    Process{
        try{
            foreach($Target in (Get-Content $TargetList)){
                Write-It -msg "Status of $Target" -type "Information"
                New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" 2>$null
                Get-Content -Tail 5 "$env:shareName\Windows\CCM\Perf\VolH\VHLog-$Target.txt" -ErrorAction SilentlyContinue -ErrorVariable errOut
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

<# ###OBSOLETE FUNCTION - TO BE DELETED
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
}#>

Function Move-VHParallel{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$volPath = $env:VolPath,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$MaxThreads = 10,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$TargetList = $env:OnList,
        [Parameter(Mandatory=$False,Position=3)]
            $cred = $global:Credential,
        [Parameter(Mandatory=$False,Position=4)]
            [String]$artifacts = $global:Artifacts,
        [Parameter(Mandatory=$False,Position=5)]
            $DumpMem = $env:DumpMemory,
        [Parameter(Mandatory=$False,Position=6)]
            $Plugins = $env:Plugins,
        [Parameter(Mandatory=$False,Position=7)]
            $HumanReadable = $env:HumanReadable
    )

    Process{
        $moveBlock = {
            Param($cred,[String]$target,[String]$artifacts,[String]$volPath,$DumpMem,$Plugins,$HumanReadable)
            "`nTarget is $target"
            Invoke-Command -ComputerName $target -Credential $cred -ArgumentList $artifacts -ScriptBlock{
                if(!(Test-Path -Path "C:\Windows\CCM\Perf\VolH\")){
                    New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\") | %{$_.Attributes = "hidden"}
                    New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Image\")
                    New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\")
                    New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Tools\")
                }
                if($artifacts){
                    New-Item -ItemType Directory -Path ("C:\Windows\CCM\Perf\VolH\Artifacts\")
                }
            } #End Invoke-Command
            $Session = New-PSSession -ComputerName $target -Credential $cred
            if( (Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {[intptr]::size}) -ne 4){
                Copy-Item -Path $volPath\bin\DumpIt-64.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe" -ToSession $Session
            }
            else{
                Copy-Item -Path $volPath\bin\DumpIt-86.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe" -ToSession $Session
            }
            Copy-Item -Path $volPath\bin\volatility.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe" -ToSession $Session
            Copy-Item -Path $volPath\bin\VolHunterRemote.ps1 -Destination "C:\Windows\CCM\Perf\VolH\Tools\VolHunterRemote.ps1" -ToSession $Session
            Disconnect-PSSession $Session
            Remove-PSSession $Session

            try{
                $scriptBlock = {
                    Param([string]$dump,[string]$plugin,[string]$human,[string]$arts)
                    Start-Process powershell.exe -ArgumentList "-c C:\Windows\CCM\Perf\VolH\Tools\VolHunterRemote.ps1 $dump $plugin $human $arts"
                }
                #Write-Host "Plugins are $Plugins and dump is $DumpMem"
                Invoke-Command -ComputerName $target -Credential $cred -InDisconnectedSession -ScriptBlock $scriptBlock -ArgumentList $DumpMem,$Plugins,$HumanReadable,$Artifacts -ErrorVariable results 2>$null
                if($results -like "*Disconnected sessions are supported only*"){
                    throw 'PS less than v3'
                }
            }
            catch{
                "`nTarget running < PSv3, trying WMIC`n"
                Get-WmiObject -List -Class Win32_OperatingSystem -Computer $target -ErrorVariable results 1>$null 2>$null
                if($results -like "*Could not get*"){
                    return
                }
                else{
                    $targIP = [Net.Dns]::GetHostAddresses("$target") | select-object IPAddressToString -expandproperty IPAddressToString
                    WMIC /node:"$targIP" process call create "powershell.exe -c C:\Windows\CCM\Perf\VolH\Tools\VolHunterRemote.ps1 -dumpFlag $DumpMem $Plugins $HumanReadable $Artifacts" 2>$null
                }
            }
        } #End moveBlock

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
                Start-Job -ScriptBlock $moveBlock -Name $target -ArgumentList $cred, $target, $artifacts, $volPath, $DumpMem, $Plugins, $HumanReadable 1>$null
                $XYZ++
                Write-It -msg "Copying files to $target   # $XYZ / $lineCount" -type "Other"
            }
            Write-It -msg "All jobs started. Waiting for them to finish." -type "Information"
            $lastX = $MaxThreads
            While (@(Get-Job -State running).count -gt 0){
                $x = @(Get-Job -State running).count
                if($lastX -ne $x){
                    Write-It -msg "Still copying to $x systems" -type "Information"
                    foreach($job in Get-Job){
                        if($job.State -eq "Running"){
                            Write-Host $job.Name
                        }
                    }
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
            $time = Get-Date
            Write-It -msg "All copies finished. Cleaning up. $time" -type "Information"
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
            Invoke-Command -Computer $target -Credential $cred -ScriptBlock {Remove-Item -path C:\Windows\CCM\Perf\VolH -Recurse -Force} -ErrorAction SilentlyContinue
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
            Invoke-Command -Computer $target -Credential $cred -ScriptBlock {$hostname = hostname; Remove-Item -path "C:\Windows\SoftwareDistribution\DataStore\$hostname.edb" -Force} -ErrorAction SilentlyContinue
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
                Start-Job -ScriptBlock $block -Name $target -ArgumentList $target, $env:DumpMemory, $env:VolPath, $env:Plugins, $env:HumanReadable, $env:Artifacts, $cred 1>$null
                $XYZ++
                Write-It -msg "Starting job against $target # $XYZ / $lineCount" -type "Other"
            }
            Write-It -msg "All jobs started. Waiting for them to finish." -type "Information"
            $lastX = $MaxThreads
            While (@(Get-Job -State running).count -gt 0){
                $x = @(Get-Job -State running).count
                if($lastX -ne $x){
                    Write-It -msg "Still running $x jobs" -type "Information"
                    foreach($job in Get-Job){
                        if($job.State -eq "Running"){
                            Write-Host $job.Name
                        }
                    }
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
            $time = Get-Date
            Write-It -msg "All jobs finished. Cleaning up. $time" -type "Information"
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
                        Start-Process powershell.exe -ArgumentList "-c C:\Windows\CCM\Perf\VolH\Tools\VolHunterRemote.ps1 $dump $plugin $human $arts"
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
                        WMIC /node:"$targIP" process call create "powershell.exe -c C:\Windows\CCM\Perf\VolH\Tools\VolHunterRemote.ps1 -dumpFlag $DumpMem $Plugins $HumanReadable $Artifacts" 2>$null
                    }
                }
            } #End $runBlock
            Move-VHParallel -volPath $env:VolPath -TargetList $env:OnList -cred $global:Credential -artifacts $env:Artifacts -DumpMem $env:DumpMemory -Plugins $env:Plugins -HumanReadable $env:HumanReadable
        }
        catch{
            Write-Error -Message "$_ Run-VHRemote failed"
        }
    }
}

Function Test-VHConnection{
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
        $time = Get-Date
        Write-It -msg "On/Off checks done at $time" -type "Information"
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
                            if(!(Test-Connection -ComputerName $target -BufferSize 16 -Count 1 -Quiet)){
                               Write-It -msg "$target appears to be offline" -type "Error"
                               $array[$index] = $True
                               $doneCount++
                               $numFailed += 1
                               continue
                            }
                            New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" -ErrorAction SilentlyContinue 1>$null
                            #write-host "priortoif"
                            if(!(Test-Path -Path "$env:shareName\Windows\CCM\Perf\VolH\VHLog*")){
                            Write-It -msg "FAILURE: $target has failed to start VolHunterRemote" -type "Error"
                                $array[$index] = $True
                                $doneCount++
                                $numFailed += 1
                            }
                            else{
                                Write-It -msg "SUCCESS: $target started VolHunterRemote" -type "Success"
                            }
                            Remove-PSDrive -Name "$env:shareLetter" -ErrorAction SilentlyContinue
                        }
                        New-PSDrive -Name "$env:shareLetter" -Credential $global:Credential -Persist -PSProvider "FileSystem" -Root "\\$target\C$" -ErrorAction SilentlyContinue 1>$null
                        if(Test-Path "$env:shareName\Windows\CCM\Perf\VolH\VolDone.txt"){
                            $date = Get-Date
                            Write-It -msg "$target completed $date" -type "Other"
                            $array[$index] = $True
                            $doneCount++
                            Write-It -msg "$doneCount of $targetLength targets complete." -type "Information"
                        }
                        Remove-PSDrive -Name "$env:shareLetter" -ErrorAction SilentlyContinue
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

Function Stop-VHRemote{
<#
.SYNOPSIS
Force kills powershell & volatility on remote targets
Warning, blunt instrument, may interrupt other's powershell
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList
    )

    Process{
        try{
            foreach($comp in (Get-Content $TargetList)){
                taskkill /IM powershell.exe /S $comp
                taskkill /IM volatility.exe /S $comp
            }
        }
        catch{
            Write-Error -Message "$_ Stop-VHRemote failed."
        }
    }
}

Export-ModuleMember -Function Get-*
Export-ModuleMember -Function Remove-*
Export-ModuleMember -Function Set-*
Export-ModuleMember -Function Convert-VHElastic
Export-ModuleMember -Function Format-VHReport
Export-ModuleMember -Function Start-VHInvestigation
Export-ModuleMember -Function Stop-VHRemote
Export-ModuleMember -Function Send-VHResults
Export-ModuleMember -Function Test-VHConnection
Export-ModuleMember -Function Test-VHShareName
Export-ModuleMember -Function Watch-VHStatus
