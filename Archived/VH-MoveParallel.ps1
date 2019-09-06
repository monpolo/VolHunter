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
        #Needs target list, credential, artifacts, volPath
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