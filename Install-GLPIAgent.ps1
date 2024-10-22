# Define variables
$glpiAgentUrl = "https://github.com/glpi-project/glpi-agent/releases/download/1.11/glpi-agent-1.11-x64.msi"
$installerPath = "$env:TEMP\glpi-agent.msi"
$serverUrl = "http://<your_glpi_server>/front/inventory.php"
$configFilePath = "C:\Program Files\GLPI-Agent\etc\agent.cfg"
$serviceName = "GLPI-Agent"
$installDir = "C:\Program Files\GLPI-Agent"

# Function to configure NetInventory and NetDiscovery
function Configure-GLPIAgent {
    if (-Not (Test-Path $configFilePath)) {
        Write-Output "Configuration file not found. Creating configuration file..."
        New-Item -ItemType File -Path $configFilePath -Force
    }

    Write-Output "Configuring NetInventory and NetDiscovery..."
    Add-Content -Path $configFilePath -Value "[server]"
    Add-Content -Path $configFilePath -Value "server = $serverUrl"

    Add-Content -Path $configFilePath -Value "[network]"
    Add-Content -Path $configFilePath -Value "netinventory = yes"
    Add-Content -Path $configFilePath -Value "netdiscovery = yes"
}

# Download the GLPI Agent installer
Write-Output "Downloading GLPI Agent..."
Invoke-WebRequest -Uri $glpiAgentUrl -OutFile $installerPath

# Verify that the installer was downloaded
if (-Not (Test-Path $installerPath)) {
    Write-Output "Failed to download GLPI Agent installer."
    exit 1
}

# Check if GLPI Agent is already installed
$glpiAgentInstalled = Test-Path $installDir

if ($glpiAgentInstalled) {
    Write-Output "GLPI Agent is already installed. Updating..."
    Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart", "SERVER=$serverUrl" -Wait
} else {
    Write-Output "GLPI Agent is not installed. Installing..."
    Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart", "SERVER=$serverUrl" -Wait
}

# Wait for the installation to complete and the system to register it
Start-Sleep -Seconds 10

# Verify installation by checking for the installation directory
$glpiAgentInstalled = Test-Path $installDir

if ($glpiAgentInstalled) {
    Write-Output "GLPI Agent installed/updated successfully."
} else {
    Write-Output "GLPI Agent installation/update failed."
    exit 1
}

# Configure NetInventory and NetDiscovery
Configure-GLPIAgent

# Restart the GLPI Agent service to apply the new configuration
Write-Output "Restarting GLPI Agent service..."
Restart-Service -Name $serviceName

# Cleanup
Write-Output "Cleaning up..."
Remove-Item -Path $installerPath -Force

Write-Output "Installation and configuration completed."
