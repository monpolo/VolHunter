<#
.HELP
Version # 1.4
#>

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
        function genReport{
          Param([String]$path,[String]$plugin,[String]$hostname,$workbook,$row,$column)
          if((test-path "$path\GatheredLogs\$plugin-$hostname.txt") -and ((get-item "$path\GatheredLogs\$plugin-$hostname.txt").length -gt 0)){
              $workbook.worksheets.Item(1).Cells.Item($row,$column).Interior.ColorIndex = 4
          }
          elseif((test-path "$path\GatheredLogs\$plugin-$hostname.txt") -and ((get-item "$path\GatheredLogs\$plugin-$hostname.txt").length -eq 0)){
              $workbook.worksheets.Item(1).Cells.Item($row,$column).Interior.ColorIndex = 6
          }
          else{
              $workbook.worksheets.Item(1).Cells.Items($row,$column).Interior.ColorIndex = 3
          }
        }
        while($bob -notlike $null){
            $bob = ($wb.Sheets.Item("Sheet1").Cells.Item($i,1).Text)
            genReport -path $path -plugin "malfind" -hostname $bob -workbook $wb -row $i -column 2
            genReport -path $path -plugin "ssdt" -hostname $bob -workbook $wb -row $i -column 3
            genReport -path $path -plugin "cmdline" -hostname $bob -workbook $wb -row $i -column 4
            genReport -path $path -plugin "dlllist" -hostname $bob -workbook $wb -row $i -column 5
            genReport -path $path -plugin "ldrmodules" -hostname $bob -workbook $wb -row $i -column 6
            genReport -path $path -plugin "netscan" -hostname $bob -workbook $wb -row $i -column 7
            genReport -path $path -plugin "psxview" -hostname $bob -workbook $wb -row $i -column 8
            genReport -path $path -plugin "timers" -hostname $bob -workbook $wb -row $i -column 9
            genReport -path $path -plugin "pslist" -hostname $bob -workbook $wb -row $i -column 10
            $bob
            $bob = ($wb.Sheets.Item("Sheet1").Cells.Item(($i + 1),1).Text)
            if($bob -like $null){ break}
            $i++
        }
        $wb.SaveAs("$fullpath")
        $wb.Close()
        $Excel.Quit()
    }
    catch{Write-Error -Message "$_ Format-VHReport failed"}
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

Function Get-VHMemDump{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target
    )
    Process{
        try{
            $status = invoke-command -computerName $Target -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VolDone.txt}
            if($status){
                Write-Host "Copying memory dump from $target" -BackgroundColor White -ForegroundColor Black
                $session = New-PSSession -ComputerName $target -Credential $global:Credential
                Copy-Item -path C:\Windows\CCM\Perf\VolH\Image\*.bin -Destination $env:VolPath\GatheredLogs\ -FromSession $session
                Disconnect-PSSession $session
                Remove-PSSession $session
            }
            else{
                Write-Host "$Target is still working" -BackgroundColor Red -ForegroundColor Black
            }
        }
        catch{Write-Error -Message "$_ Get-VHMemDump failed"}
    }
}

Function Get-VHOutput{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:OnList,
        [Parameter(Mandatory=$False,Position=1)]
            [Switch]$skipOfflines
    )
    Process{
        $lineCount = (Get-Content $TargetList | Measure-Object -Line).Lines
        $currLine = 0
        foreach($target in get-content $TargetList){
            try{
                $currLine++
                if(!(Test-Connection -ComputerName $target -BufferSize 16 -Count 1 -Quiet)){
                    Write-It -msg "$target appears offline" -type "Warning"
                    if($skipOfflines){continue}
                }
                $status = invoke-command -computerName $Target -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VolDone.txt}
                if($status){
                    Write-Host "Copying output from $target" -BackgroundColor White -ForegroundColor Black
                    $session = New-PSSession -ComputerName $target -Credential $global:Credential
                    Copy-Item -path C:\Windows\CCM\Perf\VolH\Output\* -Destination $env:VolPath\GatheredLogs\ -FromSession $session
                    Copy-Item -path C:\Windows\CCM\Perf\VolH\VHLog-*.txt -Destination $env:VolPath\VHLogs\ -FromSession $session
                    Copy-Item -path C:\Windows\CCM\Perf\VolH\VolProfile.txt -Destination $env:VolPath\VHLogs\$target-profile.txt -FromSession $session
                    Disconnect-PSSession $session
                    Remove-PSSession $session
                }
                else{
                    Write-Host "$Target is still working" -BackgroundColor Red -ForegroundColor Black
                }
            }
            catch{Write-Error -Message "$_ Get-VHOutput failed"}
        }
    }
}

Function Get-VHStatus{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [String]$Target2
    )
    Process{
        try{
            $status = invoke-command -computerName $Target2 -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VolDone.txt}
            if($status){
                Write-Host "$Target2 is done" -backgroundColor DarkGreen -ForegroundColor White
            }
            else{
                Write-Host "$Target2 is still working" -BackgroundColor Red -ForegroundColor Black
            }
        }
        catch{Write-Error -Message "$_ Get-VHStatus failed"}
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

                $status = invoke-command -computerName $Target -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VolDone.txt}
                if($status){
                    Write-Host "$Target is done" -backgroundColor DarkGreen -ForegroundColor White
                }
                else{
                    Write-Host "$Target is still working" -BackgroundColor Red -ForegroundColor Black
                }
            }
        }
        catch{Write-Error -Message "$_ Get-VHStatus failed"}
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
            $URI = $ElasticIP + ":" + $ElasticPort + "/VolHunter"
            curl -Method DELETE $URI >$null
            Write-It -msg "VolHunter index cleared" -type "Information"
        }
        catch{Write-Error -Message "$_ Remove-VHIndices failed"}
    }
}

Function Remove-VHRemote{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList,
        [Parameter(Mandatory=$False,Position=1)]
            [Int]$MaxThreads = $env:MaxThreads
    )
    Process{
        $cleanBlock = {
            Param([string]$target, $cred, $volPath)
            "`nTarget is $target"
            Invoke-Command -Computer $target -Credential $cred -ScriptBlock {Remove-Item -path C:\Windows\CCM\Perf\VolH -Recurse -Force} -ErrorAction SilentlyContinue
            "`nFiles and folders deleted`n"
        }
        Run-VHRemote -block $cleanBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
    }
}

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
            $cred = $global:Credential,
        [Parameter(Mandatory=$False,Position=4)]
            $volPath = $env:VolPath
    )
    Process{
        try{
            $XYZ = 0
            Get-Job | Remove-Job -force
            $volPath = $env:VolPath
            $lineCount = (Get-Content $TargetList | Measure-Object -Line).Lines
            Write-It -msg "Running commands against $lineCount targets - Max of $MaxThreads simultaneously" -type "Information"
            foreach ($target in Get-Content $TargetList){
                While (@(Get-Job -State running).count -ge $MaxThreads){
                    Start-Sleep -Milliseconds 10
                }
                Start-Job -ScriptBlock $block -Name $target -ArgumentList $target, $cred, $volPath 1>$null
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
            $time = Get-Date
            Write-It -msg "All jobs finished. Cleaning up. $time" -type "Information"
            Get-Job | Remove-Job -ErrorAction SilentlyContinue
        }
        catch{Write-Error -Message "$_ Run-VHRemote failed"}
    }
}

Function Set-VHInvestigated{
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
            [String]$VolPath = (Get-Location).Path,
        [Parameter(Mandatory=$True,Position=6)]
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

Function Start-VHExecutionCleanup{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = ".\OnList.txt",
        [Parameter(Mandatory=$False,Position=1)]
            [String]$MaxThreads = $env:MaxThreads
    )
    Process{
        try{
            $cred = $global:Credential
            $rerunBlock = {
                Param([String]$target,$cred,[String]$volPath)
                Invoke-Command -InDisconnectedSession -ComputerName $target -Credential $cred -ScriptBlock{
                    function Run-Vol{
                        param( [string]$plugin, [string]$logLocation, [string]$outputDir, [string]$imgLocation, [string]$volProfile )
                        try{
                            $command = "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe"
                            $hn = hostname
                            Add-Content -Path $logLocation -Value "Running $plugin plugin`n"
                            $start = Get-Date

                            $outFile = $outputDir + $plugin + "-" + $hn + ".txt"
                            $timeouted = $null
                            $proc = Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin" -RedirectStandardOutput $outFile -PassThru
                            $proc | Wait-Process -Timeout 3600 -ErrorAction SilentlyContinue -ErrorVariable timeouted

                            if($timeouted){
                                $proc | kill
                                $end = Get-Date
                                Add-Content -Path $logLocation -Value "$plugin plugin timed-out in $($end-$start)`n"
                                continue
                            }

                            $end = Get-Date
                            Add-Content -Path $logLocation -Value "$plugin plugin completed in $($end-$start) H:M:S.MS`n"
                        }
                        catch{
                            Add-Content -Path $logLocation -Value "$_ $plugin failed"
                            continue
                        }
                    } #End RunVol

                    $hostName = hostname
                    $hostImg = $hostName + ".bin"
                    $baseDir = "C:\Windows\CCM\Perf\VolH\"
                    $imageDir = "C:\Windows\CCM\Perf\VolH\Image\"
                    $outputDir = "C:\Windows\CCM\Perf\VolH\Output\"
                    $toolDir = "C:\Windows\CCM\Perf\VolH\Tools\"
                    $imgLocation = "C:\Windows\CCM\Perf\VolH\Image\$hostImg"
                    $logLocation = "C:\Windows\CCM\Perf\VolH\VHLog-$hostname.txt"
                    $time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"+"T"+"HH:mm:ss.fff"+"Z")
                    $volProfile = Get-Content "C:\Windows\CCM\Perf\VolH\VolProfile.txt"
                    $OSVersi = [System.Environment]::OSVersion.Version

                    if( !(Test-Path $imgLocation) ){
                        Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 comae.io"
                        $dumpCommand = "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe"
                        Add-Content -Path "$logLocation" -Value "Starting memory dump"
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

                    $backupTemp = $env:temp
                    $env:temp = "C:\Windows\CCM\Perf\VolH\"
                    $env:tmp = "C:\Windows\CCM\Perf\VolH\"
                    if( !(Test-Path "$outputDir\malfind-*") -or ((Get-ItemProperty "$outputDir\malfind-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "malfind" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\ssdt-*") -or ((Get-ItemProperty "$outputDir\ssdt-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "ssdt" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\cmdline-*") -or ((Get-ItemProperty "$outputDir\cmdline-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "cmdline" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\dlllist-*") -or ((Get-ItemProperty "$outputDir\dlllist-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "dlllist" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\ldrmodules-*") -or ((Get-ItemProperty "$outputDir\ldrmodules-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "ldrmodules" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\netscan-*") -or ((Get-ItemProperty "$outputDir\netscan-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "netscan" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\psxview-*") -or ((Get-ItemProperty "$outputDir\psxview-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "psxview" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\timers-*") -or ((Get-ItemProperty "$outputDir\timers-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "timers" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }
                    if( !(Test-Path "$outputDir\pslist-*") -or ((Get-ItemProperty "$outputDir\pslist-*").length -eq 0) ){
                        taskkill /F /IM volatility.exe
                        Run-Vol -plugin "pslist" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    }

                    $vhlog = "DONE"
                    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolDone.txt" -InputObject $vhlog -Encoding ASCII

                    ### FIX TEMP FOLDER CHANGE ###
                    $env:temp = $backupTemp
                    $env:tmp = $backupTemp
                    Add-Content -Path "$logLocation" -Value "Temp environment variables restored`n"
                }
            }

            Write-Host "SENDING RERUN COMMANDS" -ForegroundColor Black -BackgroundColor Green
            Run-VHRemote -block $rerunBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
        }
        catch{Write-Error -Message "$_ Start-VHExecutionCleanup failed"}
    }
}

Function Start-VHInvestigation{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = ".\OnList.txt",
        [Parameter(Mandatory=$False,Position=1)]
            [String]$MaxThreads = $env:MaxThreads,
        [Parameter(Mandatory=$False,Position=2)]
            [String]$HumanReadable = $env:HumanReadable
    )
    Process{
        try{
            $cred = $global:Credential
            $numOff = Test-VHConnection
            Write-Host "$numOff systems offline"
            $exeBlock = {
                Param([String]$target,$cred,[String]$volPath)
                Invoke-Command -InDisconnectedSession -ComputerName $target -Credential $cred -ScriptBlock{
                    function Run-Vol{
                        param( [string]$plugin, [string]$logLocation, [string]$outputDir, [string]$imgLocation, [string]$volProfile )
                        try{
                            $command = "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe"
                            $hn = hostname
                            Add-Content -Path $logLocation -Value "Running $plugin plugin`n"
                            $start = Get-Date

                            $outFile = $outputDir + $plugin + "-" + $hn + ".txt"
                            $timeouted = $null
                            $proc = Start-Process -FilePath $command -ArgumentList "-f $imgLocation --profile=$volProfile $plugin" -RedirectStandardOutput $outFile -PassThru
                            $proc | Wait-Process -Timeout 3600 -ErrorAction SilentlyContinue -ErrorVariable timeouted

                            if($timeouted){
                                $proc | kill
                                $end = Get-Date
                                Add-Content -Path $logLocation -Value "$plugin plugin timed-out in $($end-$start)`n"
                                continue
                            }

                            $end = Get-Date
                            Add-Content -Path $logLocation -Value "$plugin plugin completed in $($end-$start) H:M:S.MS`n"
                        }
                        catch{
                            Add-Content -Path $logLocation -Value "$_ $plugin failed"
                            continue
                        }
                    }

                    $hostName = hostname
                    $hostImg = $hostName + ".bin"
                    $baseDir = "C:\Windows\CCM\Perf\VolH\"
                    $imageDir = "C:\Windows\CCM\Perf\VolH\Image\"
                    $outputDir = "C:\Windows\CCM\Perf\VolH\Output\"
                    $toolDir = "C:\Windows\CCM\Perf\VolH\Tools\"
                    $imgLocation = "C:\Windows\CCM\Perf\VolH\Image\$hostImg"
                    $logLocation = "C:\Windows\CCM\Perf\VolH\VHLog-$hostname.txt"
                    $time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"+"T"+"HH:mm:ss.fff"+"Z")
                    $volProfile = Get-Content "C:\Windows\CCM\Perf\VolH\VolProfile.txt"
                    $OSVersi = [System.Environment]::OSVersion.Version

                    $vhlog = "Starting VolHunter at $time `n"
                    Out-File -FilePath "$logLocation" -InputObject $vhlog -Encoding ASCII

                    ### DETERMINE VOLATILITY PROFILE ###
                    Add-Content -Path "$logLocation" -Value "Determining x86 vs x64`n"
                    ### Determine 32 vs 64 bit architecture
                    $Architecture = 64
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
                    Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 comae.io"
                    $dumpCommand = "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe"
                    Add-Content -Path "$logLocation" -Value "Starting memory dump"
                    $start = Get-Date
                    Start-Process -Filepath $dumpCommand -ArgumentList "/Q /N /J /T RAW /OUTPUT $imgLocation" -wait
                    $end = Get-Date
                    $dumpDone = "DumpIt Completed"
                    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\DumpDone.txt" -InputObject $dumpDone -Encoding ASCII
                    Get-Content "C:\Windows\System32\drivers\etc\hosts" | Where-Object {$_ -notmatch 'comae'} | Set-Content "C:\Windows\System32\drivers\etc\hosts2"
                    Get-Content "C:\Windows\System32\drivers\etc\hosts2" | Set-Content "C:\Windows\System32\drivers\etc\hosts"
                    Remove-Item "C:\Windows\System32\drivers\etc\hosts2"
                    Add-Content -Path "$logLocation" -Value "Memory dump completed in $($end-$start) H:M:S.MS`n"

                    $backupTemp = $env:temp
                    $env:temp = "C:\Windows\CCM\Perf\VolH\"
                    $env:tmp = "C:\Windows\CCM\Perf\VolH\"
                    rm "C:\Windows\CCM\Perf\VolH\VolDone.txt"
                    Run-Vol -plugin "malfind" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "ssdt" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "cmdline" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "dlllist" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "ldrmodules" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "netscan" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "psxview" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "timers" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile
                    Run-Vol -plugin "pslist" -logLocation $logLocation -outputDir $outputDir -imgLocation $imgLocation -volProfile $volProfile

                    $vhlog = "DONE"
                    Out-File -FilePath "C:\Windows\CCM\Perf\VolH\VolDone.txt" -InputObject $vhlog -Encoding ASCII

                    ### FIX TEMP FOLDER CHANGE ###
                    $env:temp = $backupTemp
                    $env:tmp = $backupTemp
                    Add-Content -Path "$logLocation" -Value "Temp environment variables restored`n"
                }
            }
            $moveBlock = {
                Param([String]$target,$cred,[String]$volPath)
                "`nTarget is $target"
                Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock{
                    if(!(Test-Path -Path "C:\Windows\CCM\Perf\VolH\")){
                        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\") | %{$_.Attributes = "hidden"}
                        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Image\")
                        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Output\")
                        New-Item -ItemType directory -Path ("C:\Windows\CCM\Perf\VolH\Tools\")
                    }
                } #End Invoke-Command
                $Session = New-PSSession -ComputerName $target -Credential $cred -Authentication Negotiate
                if( (Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {[intptr]::size}) -ne 4){
                    Copy-Item -Path $volPath\bin\DumpIt-64.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe" -ToSession $Session
                }
                else{
                    Copy-Item -Path $volPath\bin\DumpIt-86.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\DumpIt.exe" -ToSession $Session
                }
                Copy-Item -Path $volPath\bin\volatility.exe -Destination "C:\Windows\CCM\Perf\VolH\Tools\volatility.exe" -ToSession $Session
                Disconnect-PSSession $Session
                Remove-PSSession $Session
            } #End moveBlock

            ### MOVE ALL FILES
            Write-Host "BEGINNING SIMULTANEOUS FILE MOVES" -ForegroundColor Black -BackgroundColor White
            Run-VHRemote -block $moveBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
            ### EXECUTE ###
            Write-Host "BEGINNING EXECUTION" -ForegroundColor Black -BackgroundColor Green
            Run-VHRemote -block $exeBlock -MaxThreads $MaxThreads -TargetList $TargetList -cred $global:Credential -ErrorAction Continue
        }
        catch{Write-Error -Message "$_ Start-VHInvestigation overall failed"}
    }
}

Function Test-VHConnection{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,Position=0)]
            [String]$TargetList = $env:TargetList
    )
    Begin{$failPing = 0}
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
                            $status = invoke-command -computerName $Target -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VHLog*}
                            if(!($status)){
                                Write-It -msg "FAILURE: $target has failed to start VolHunterRemote" -type "Error"
                                $array[$index] = $True
                                $doneCount++
                                $numFailed += 1
                            }
                            else{
                                Write-It -msg "SUCCESS: $target started VolHunterRemote" -type "Success"
                            }
                        }
                        $status = invoke-command -computerName $Target -Credential $global:Credential -ScriptBlock{Test-path C:\Windows\CCM\Perf\VolH\VolDone.txt}
                        if($status){
                            $date = Get-Date
                            Write-It -msg "$target completed $date" -type "Other"
                            $array[$index] = $True
                            $doneCount++
                            Write-It -msg "$doneCount of $targetLength targets complete." -type "Information"
                        }
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
        catch{Write-Error -Message "$_ Watch-VHStatus failed"}
    }
}

###Not to be exposed by module
Function Write-It{
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
        catch{Write-Error -Message "$_ Write-It failed... I'm not sure how you managed this."}
    }
}

Function Stop-VHRemote{
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
        catch{Write-Error -Message "$_ Stop-VHRemote failed."}
    }
}

Export-ModuleMember -Function Get-*
Export-ModuleMember -Function Remove-*
Export-ModuleMember -Function Set-*
Export-ModuleMember -Function Convert-VHElastic
Export-ModuleMember -Function Format-VHReport
Export-ModuleMember -Function Start-VHInvestigation
Export-ModuleMember -Function Start-VHExecutionCleanup
Export-ModuleMember -Function Stop-VHRemote
Export-ModuleMember -Function Send-VHResults
Export-ModuleMember -Function Test-VHConnection
Export-ModuleMember -Function Test-VHShareName
Export-ModuleMember -Function Watch-VHStatus
