$path = (pwd).Path
$fullpath = $path + "\test.xlsx"

$excelFile = $fullpath #'C:\Users\bob\Desktop\test.xlsx'
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $false
$Excel.DisplayAlerts = $false
$wb = $Excel.Workbooks.Open($excelFile)
[int]$i = 1
$bob = ($wb.Sheets.Item("Sheet1").Cells.Item($i,1).Text)

while($bob -notlike $null){
    #$wb.Sheets.Item("Sheet1").Range("A$i").Interior.ColorIndex
    #IF EXISTS and size > 0, green, else if exists & size==0 yellow, else red
    ###SET TO RED
    ###https://docs.microsoft.com/en-us/office/vba/api/Excel.ColorIndex
    $sheet = $wb.Worksheets.Item(1)
    $sheet.Cells.Item($i,2).Interior.ColorIndex = 3

    $bob = ($wb.Sheets.Item("Sheet1").Cells.Item($i,1).Text)
    #$bob
    $bob = ($wb.Sheets.Item("Sheet1").Cells.Item(($i + 1),1).Text)
    if($bob -like $null){ break}
    $i++
}#>

$wb.SaveAs("$fullpath")
$wb.Close()
$Excel.Quit()



