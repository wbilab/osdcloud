Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Logging setup
$LogDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD"
$LogFile = Join-Path $LogDir "WindowsUpdateLog_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
New-Item -ItemType File -Path $LogFile -Force | Out-Null

function Add-LogLine($text) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $text"
    $listbox.Items.Add($line)
    $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
    $listbox.TopIndex = $listbox.Items.Count - 1
    $form.Refresh()
}

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows & Driver Update Installer"
$form.Width = 800
$form.Height = 600

$listbox = New-Object System.Windows.Forms.ListBox
$listbox.Dock = 'Fill'
$listbox.Font = 'Consolas,10'
$form.Controls.Add($listbox)

$form.TopMost = $true
$form.Show()

# Start
Start-Sleep -Seconds 2
Add-LogLine "Initializing update engine..."

Try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop
    Add-LogLine "PSWindowsUpdate module installed."
} Catch {
    Add-LogLine "Failed to install PSWindowsUpdate: $_"
    return
}

Try {
    Import-Module PSWindowsUpdate
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
    Add-LogLine "Microsoft Update enabled (includes drivers)."
} Catch {
    Add-LogLine "Failed to enable Microsoft Update: $_"
    return
}

Try {
    Add-LogLine "Scanning for available updates..."
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction Stop
    $count = $updates.Count

    if ($count -eq 0) {
        Add-LogLine "No updates available."
    } else {
        Add-LogLine "Found $count update(s)."
        foreach ($update in $updates) {
            $cat = ($update.Categories | ForEach-Object { $_.Name }) -join ", "
            Add-LogLine " → $($update.Title)  [$cat]"
        }

        Add-LogLine "Installing all updates..."
        $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction Continue

        foreach ($res in $results) {
            Add-LogLine "$($res.Title) → $($res.ResultCode)"
        }

        Add-LogLine "Update process finished."
    }

} Catch {
    Add-LogLine "Unexpected error during update process: $_"
}

Add-LogLine "Window will close in 15 seconds..."

for ($i = 15; $i -ge 1; $i--) {
    $form.Text = "Closing in $i seconds..."
    Start-Sleep -Seconds 1
}

$form.Close()
