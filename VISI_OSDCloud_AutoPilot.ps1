[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Script -Name Check-AutopilotPrerequisites -Force
Check-AutopilotPrerequisites

Add-Type -AssemblyName System.Windows.Forms
$systemDrive = $env:SystemDrive
$workingDirectory = Join-Path $systemDrive "OSDCloud\Scripts"


$rawImageUrl = "https://raw.githubusercontent.com/wbilab/osdcloud/main/Vi_Logo.png"
Invoke-WebRequest $rawImageUrl -OutFile $workingDirectory"\Vi_Logo.png"
$logo = Join-Path $workingDirectory "Vi_Logo.png"

Save-Script -Name Get-WindowsAutoPilotInfo -Path $workingDirectory -Force

# Erstelle das Hauptfenster
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "VISI AutoPilot Registrierung"
$Form.Size = New-Object System.Drawing.Size(620, 450)
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"


# Erstelle den Titel mit groesserer Schriftart
$LabelTitle = New-Object System.Windows.Forms.Label
$LabelTitle.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Bitte wählen Sie die gewünschte Funktion:$($computerInfo.OsSerialNumber")"))
$LabelTitle.Location = New-Object System.Drawing.Point(10, 70)
$LabelTitle.AutoSize = $true
$LabelTitle.Font = New-Object System.Drawing.Font("Arial", 11)

# Erstelle den Platz für das Logo
$LogoPictureBox = New-Object System.Windows.Forms.PictureBox
$LogoPictureBox.Image = [System.Drawing.Image]::FromFile($logo)
$LogoPictureBox.SizeMode = "AutoSize"
$LogoPictureBox.Location = New-Object System.Drawing.Point(10, 20)

# Erstelle den ersten Button (quadratisch und groesser)
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Text = "AutoPilot InCloud"
$Button1.Size = New-Object System.Drawing.Size(80, 80)
$Button1.Location = New-Object System.Drawing.Point(10, 120)
$Button1.Add_Click({

$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag InCloud -Online -Assign
})

# Erstelle den zweiten Button (quadratisch und groesser)
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Text = "AutoPilot Hybrid"
$Button2.Size = New-Object System.Drawing.Size(80, 80)
$Button2.Location = New-Object System.Drawing.Point(110, 120)
$Button2.Add_Click({

$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag Hybrid -Online -Assign

})


# Erstelle die Bezeichnung für das Eingabefeld "Anderes"
$LabelAnderes = New-Object System.Windows.Forms.Label
$LabelAnderes.Text = "AutoPilot Tag:"
$LabelAnderes.Location = New-Object System.Drawing.Point(210, 125)

# Erstelle ein Eingabefeld
$InputBox = New-Object System.Windows.Forms.TextBox
$InputBox.Location = New-Object System.Drawing.Point(210, 145)
$InputBox.Size = New-Object System.Drawing.Size(80, 30)

# Erstelle die "OK"-Taste
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Text = "OK"
$OKButton.Size = New-Object System.Drawing.Size(80, 30)
$OKButton.Location = New-Object System.Drawing.Point(210, 170)
$OKButton.Add_Click({
$inputValue = $InputBox.Text
$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag $inputValue -Online -Assign

})

# Erstelle den driten Button (quadratisch und groesser)
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Text = "Windows Neinstallation"
$Button3.Size = New-Object System.Drawing.Size(80, 80)
$Button3.Location = New-Object System.Drawing.Point(310, 120)
$Button3.Add_Click({
    $Form.Close() # Schliesse das Programm
})

# Füge die Steuerelemente dem Hauptfenster hinzu
$Form.Controls.Add($LabelTitle)
$Form.Controls.Add($LogoPictureBox)
$Form.Controls.Add($Button1)
$Form.Controls.Add($Button2)
$Form.Controls.Add($LabelAnderes)
$Form.Controls.Add($InputBox)
$Form.Controls.Add($OKButton)
$Form.Controls.Add($Button3)

# Zeige das GUI-Fenster an
$Form.ShowDialog()