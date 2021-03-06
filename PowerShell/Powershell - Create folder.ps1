#Powershell script that checks if any folder is in the location defined by the user, removes it and then creates a new folder with the Get-Date
#Parameters $dir_location and $date


$dir_location="\\location"
if (Test-Path -path $dir_location -PathType container) {Remove-Item -path $dir_location }
$date=Get-Date -format o | foreach {$_ -replace ":","."}
New-Item -ItemType "directory" -path $dir_location -name $date
