if (Test-Path -path "C:\Users\csotcan001\Desktop\Test" -PathType container) {Remove-Item -path "C:\Users\csotcan001\Desktop\Test" }
$date=Get-Date -format o | foreach {$_ -replace ":","."}
New-Item -ItemType "directory" -path "C:\Users\csotcan001\Desktop\Test" -name $date