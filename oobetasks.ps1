Set-ExecutionPolicy Unrestricted -Force
Install-Module OSD -Force -SkipPublisherCheck
Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force  

# Windows 10

$logonpfad = "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logon"

$ScriptPathOOBE = $(Join-Path -Path $logonpfad -ChildPath "OOBE.ps1")
$ScriptPathSendKeys = $(Join-Path -Path $logonpfad -ChildPath "SendKeys.ps1")

# Überprüfe, ob der Ordner existiert. Wenn nicht, erstelle ihn.
if (-not (Test-Path -Path (Split-Path -Path $logonpfad))) {
    New-Item -Path $logonpfad -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logoff" -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\Machine" -ItemType Directory -Force | Out-Null    
}

$OOBEScript =@"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Executing Keyboard Language Skript"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Set-KeyboardLanguage.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing VISI Autopilot Registration"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/VISI_OSDCloud_AutoPilot.ps1" -Wait

#Write-Host -ForegroundColor DarkGray "Executing OOBEDeploy Script fomr OSDCloud Module"
#Start-Process PowerShell -ArgumentList "-NoL -C Start-OOBEDeploy" -Wait

Write-Host -ForegroundColor DarkGray "Executing Cleanup Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/CleanUp.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

$SendKeysScript = @"
`# Laden der Windows-API-Bibliothek
Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;

    public class KeyboardSimulator {
        [DllImport('user32.dll')]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        public const int KEYEVENTF_KEYDOWN = 0x0001; // Key down flag
        public const int KEYEVENTF_KEYUP = 0x0002; // Key up flag

        public static void SendKey(byte keyCode, int duration) {
            keybd_event(keyCode, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
            System.Threading.Thread.Sleep(duration);
            keybd_event(keyCode, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        }
    }
'@

# Simulieren von "Shift+F10"
[KeyboardSimulator]::SendKey(0x2A, 100) # Shift-Taste drücken (0x2A ist der Code für die Shift-Taste)
[KeyboardSimulator]::SendKey(0x7D, 100) # F10-Taste drücken (0x7D ist der Code für die F10-Taste)

# Warten 5 Sekunden
Start-Sleep -Seconds 5

# Simulieren von "ALT+TAB"
[KeyboardSimulator]::SendKey(0x12, 100) # Alt-Taste (0x12 ist der Code für die Alt-Taste)
[KeyboardSimulator]::SendKey(0x09, 100) # TAB-Taste (0x09 ist der Code für die TAB-Taste)
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

$psscriptsini = @"
`
[Logon]
0CmdLine=SendKeys.ps1
0Parameters=
1CmdLine=OOBE.ps1
1Parameters=
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -InputObject $psscriptsini -Encoding ascii -Force

$gpt = @"
`[General]
gPCUserExtensionNames=[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]
Version=65536
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\gpt.ini" -InputObject $gpt -Encoding ascii -Force

Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)