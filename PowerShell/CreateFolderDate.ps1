if (Test-Path -path "C:\Users\user\Desktop\Test" -PathType container) {Remove-Item -path "C:\Users\user\Desktop\Test" }
$date=Get-Date -format o | foreach {$_ -replace ":","."}
New-Item -ItemType "directory" -path "C:\Users\user\Desktop\Test" -name $date
