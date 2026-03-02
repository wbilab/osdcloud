[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

Add-Type -AssemblyName System.Windows.Forms

$workingDirectory = "C:\OSDCloud"
if (-not (Test-Path $workingDirectory)) { New-Item -Path $workingDirectory -ItemType Directory -Force | Out-Null }

$Script:AutoPilotStatus = "Aborted"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Check-AutopilotPrerequisites.log"
Start-Transcript -Path (Join-Path "$workingDirectory\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute Autopilot Prerequitites Check" -ForegroundColor Green

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Script -Name Check-AutopilotPrerequisites -Force
Check-AutopilotPrerequisites

Stop-Transcript

$logDateiPfad = (Join-Path "$workingDirectory\" $Global:Transcript)
$logInhalt = Get-Content -Path $logDateiPfad

$KeyboardlayoutZeile = $logInhalt | Where-Object { $_ -match "Keyboardlayout" }
$tpmpresentZeile = $logInhalt | Where-Object { $_ -match "Tpm present" }
$tpmreadyZeile = $logInhalt | Where-Object { $_ -match "Tpm ready" }
$tpmenabledZeile = $logInhalt | Where-Object { $_ -match "Tpm enabled" }
$biosserialnummerZeile = $logInhalt | Where-Object { $_ -match "Bios Serialnumber" }
$approfileZeile = $logInhalt | Where-Object { $_ -match "Cached AP Profile" }

$Keyboardlayout = ($KeyboardlayoutZeile -split ":")[1].Trim()
$tpmpresent = ($tpmpresentZeile -split ":")[1].Trim()
$tpmready = ($tpmreadyZeile -split ":")[1].Trim()
$tpmenabled= ($tpmenabledZeile -split ":")[1].Trim()
$biosserialnummer = ($biosserialnummerZeile -split ":")[1].Trim()
$approfile = ($approfileZeile -split ":")[1].Trim()

$rawImageUrl = "https://raw.githubusercontent.com/wbilab/osdcloud/main/Vi_Logo.png"
Invoke-WebRequest $rawImageUrl -OutFile (Join-Path $workingDirectory "Vi_Logo.png")
$logo = Join-Path $workingDirectory "Vi_Logo.png"

Save-Script -Name Get-WindowsAutoPilotInfo -Path $workingDirectory -Force

[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "VISI AutoPilot Registrierung"
$Form.Size = New-Object System.Drawing.Size(500, 450)
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"

$LabelTitle = New-Object System.Windows.Forms.Label
$LabelTitle.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Bitte wählen Sie die gewünschte Funktion:"))
$LabelTitle.Location = New-Object System.Drawing.Point(10, 70)
$LabelTitle.AutoSize = $true
$LabelTitle.Font = New-Object System.Drawing.Font("Arial", 11)

$LogoPictureBox = New-Object System.Windows.Forms.PictureBox
$LogoPictureBox.Image = [System.Drawing.Image]::FromFile($logo)
$LogoPictureBox.SizeMode = "AutoSize"
$LogoPictureBox.Location = New-Object System.Drawing.Point(10, 20)

$Button1 = New-Object System.Windows.Forms.Button
$Button1.Text = "AutoPilot`nRegistrierung`n`nTag: InCloud"
$Button1.Size = New-Object System.Drawing.Size(100, 100)
$Button1.Location = New-Object System.Drawing.Point(10, 120)
$Button1.Add_Click({
    $LabelTitle.Text = "Registrierung läuft. Bitte im Konsolenfenster prüfen..."
    $LabelTitle.ForeColor = 'Red'
    $Form.Refresh()

    $Form.WindowState = "Minimized" 
    cd $workingDirectory
    .\Get-WindowsAutoPilotInfo.ps1 -GroupTag InCloud -Online -Assign
    $Script:AutoPilotStatus = "Success"
    $Form.Close() 
})

$Button2 = New-Object System.Windows.Forms.Button
$Button2.Text = "AutoPilot`nRegistrierung`n`nTag: Hybrid"
$Button2.Size = New-Object System.Drawing.Size(100, 100)
$Button2.Location = New-Object System.Drawing.Point(120, 120)
$Button2.Add_Click({
    $LabelTitle.Text = "Registrierung läuft. Bitte im Konsolenfenster prüfen..."
    $LabelTitle.ForeColor = 'Red'
    $Form.Refresh()

    $Form.WindowState = "Minimized" 
    cd $workingDirectory
    .\Get-WindowsAutoPilotInfo.ps1 -GroupTag Hybrid -Online -Assign
    $Script:AutoPilotStatus = "Success"
    $Form.Close() 
})

$LabelAnderes = New-Object System.Windows.Forms.Label
$LabelAnderes.Text = "AutoPilot`nRegistrierung"
$LabelAnderes.Size = New-Object System.Drawing.Size(100, 30)
$LabelAnderes.Location = New-Object System.Drawing.Point(230, 125)

$LabelTag = New-Object System.Windows.Forms.Label
$LabelTag.Size = New-Object System.Drawing.Size(30, 20)
$LabelTag.Text = "Tag:"
$LabelTag.Location = New-Object System.Drawing.Point(230, 170)

$InputBox = New-Object System.Windows.Forms.TextBox
$InputBox.Location = New-Object System.Drawing.Point(260, 165)
$InputBox.Size = New-Object System.Drawing.Size(70, 50)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Text = "OK"
$OKButton.Size = New-Object System.Drawing.Size(100, 30)
$OKButton.Location = New-Object System.Drawing.Point(230, 190)
$OKButton.Add_Click({
    $LabelTitle.Text = "Registrierung läuft. Bitte im Konsolenfenster prüfen..."
    $LabelTitle.ForeColor = 'Red'
    $Form.Refresh()

    $inputValue = $InputBox.Text
    $Form.WindowState = "Minimized" 
    cd $workingDirectory
    .\Get-WindowsAutoPilotInfo.ps1 -GroupTag $inputValue -Online -Assign
    $Script:AutoPilotStatus = "Success"
    $Form.Close() 
})

$Button3 = New-Object System.Windows.Forms.Button
$Button3.Text = "AutoPilot Registrierung`nschliessen"
$Button3.Size = New-Object System.Drawing.Size(100, 100)
$Button3.Location = New-Object System.Drawing.Point(350, 120)
$Button3.Add_Click({
    $Form.Close() 
})

$precheckText = "Autopilot PreCheck Results:`n`nKeyboardlayout: $Keyboardlayout`nTpm present: $tpmpresent`nTpm ready: $tpmready`nTpm enabled: $tpmenabled`nSerienumber: $biosserialnummer`nAutoPilot Registration: $approfile"

$precheck = New-Object Windows.Forms.Label
$precheck.Text = $precheckText
$precheck.Width = 380
$precheck.Height = 120
$precheck.Location = New-Object Drawing.Point(10, 250)
$precheck.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$LabelClose = New-Object System.Windows.Forms.Label
$LabelClose.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Das Gerät ist bereits im AutoPilot registriert.`nDas Fenster wird in 15 Sekunden automatisch geschlossen!"))
$LabelClose.AutoSize = $true
$LabelClose.ForeColor = [System.Drawing.Color]::Green
$LabelClose.Location = New-Object System.Drawing.Point(10, 380)

if ($approfile -eq "Assigned") {
    $Button1.Enabled = $false
    $Button2.Enabled = $false
    $OKButton.Enabled = $false
    $InputBox.Enabled = $false
    $Button3.Enabled = $true
    
    $Script:AutoPilotStatus = "Success"

    $CountdownDuration = 15 
    $CountdownTimer = [System.Diagnostics.Stopwatch]::StartNew()

    function UpdateCountdownText() {
        $RemainingTime = $CountdownDuration - [math]::Round($CountdownTimer.Elapsed.TotalSeconds)
        if ($RemainingTime -le 0) {
            $Form.Close()
        }
    }

    $CountdownUpdateTimer = New-Object System.Windows.Forms.Timer
    $CountdownUpdateTimer.Interval = 1000  
    $CountdownUpdateTimer.Add_Tick({ UpdateCountdownText })
    $CountdownUpdateTimer.Start()
    
    $Form.Controls.Add($LabelClose)

} else {
    $Button1.Enabled = $true
    $Button2.Enabled = $true
    $OKButton.Enabled = $true
    $InputBox.Enabled = $true
    $Button3.Enabled = $true
}

$Form.Controls.Add($LabelTitle)
$Form.Controls.Add($LogoPictureBox)
$Form.Controls.Add($LabelAnderes)
$Form.Controls.Add($LabelTag)
$Form.Controls.Add($InputBox)
$Form.Controls.Add($precheck)
$form.Controls.AddRange(@($Button1, $Button2, $Button3,$OKButton))

[void][Win32]::SetForegroundWindow($form.Handle)
$Form.ShowDialog()

$FlagPath = "C:\OSDCloud\AutopilotDone.flag"
Set-Content -Path $FlagPath -Value $Script:AutoPilotStatus -Force