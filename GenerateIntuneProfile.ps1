# Includes
. ".\inc\Log.ps1"

# Intune specific Includes
. ".\inc\ConnectToGraph.ps1"
. ".\inc\GrabIntuneProfiles.ps1"
    
New-Item -Force -ItemType directory -Path "overlays\install\Windows\Provisioning\Autopilot\"

Write-Host "Installing Intune modules if required (current user scope)"
#Install MS Graph if not available
if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
    Write-Host "Microsoft Graph Already Installed"
} 
else {
    Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery -Force 
}
import-module microsoft.graph.authentication

Connect-ToGraph -scopes "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All, Domain.ReadWrite.All, Organization.Read.All"
##Grab all profiles and output to gridview
$selectedprofile = GrabProfiles

##Grab JSON for selected profile
$profilejson = grabandoutput -id $selectedprofile
$profilejson | Set-Content -Encoding Ascii "overlays\windows\base\Windows\Provisioning\Autopilot\AutopilotConfigurationFile.json"

Write-Host "All Done!"