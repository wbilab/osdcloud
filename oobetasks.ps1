if ([System.Environment]::OSVersion.Version -ge (New-Object Version "10.0.22000.0")) {
write-Host -ForegroundColor DarkGray "Win11"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/oobetasks-Win11.ps1" -Wait
}
else{
write-Host -ForegroundColor DarkGray "Win10"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/oobetasks-Win10.ps1" -Wait
}