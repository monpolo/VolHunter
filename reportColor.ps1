$path = (pwd).Path
$reportName = Read-Host -Prompt "Enter report name to run:"
$fullpath = $path + "\$reportName.xlsx"

$excelFile = $fullpath #'C:\Users\bob\Desktop\$reportName.xlsx'
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