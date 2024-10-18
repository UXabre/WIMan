
function GrabProfiles() {
    # Defining Variables
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    $response = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject

    $profiles = $response.value

    $profilesNextLink = $response."@odata.nextLink"

    while ($null -ne $profilesNextLink) {
        $profilesResponse = (Invoke-MGGraphRequest -Uri $profilesNextLink -Method Get -outputType PSObject)
        $profilesNextLink = $profilesResponse."@odata.nextLink"
        $profiles += $profilesResponse.value
    }

    $selectedprofile = $profiles | out-gridview -passthru -title "Select a profile"
    return $selectedprofile.id
}

function grabandoutput() {
    [cmdletbinding()]

    param
    (
        [string]$id

    )

    # Defining Variables
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id"
    $approfile = Invoke-MGGraphRequest -Uri $uri -Method Get -OutputType PSObject

    # Set the org-related info
    $script:TenantOrg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/organization" -OutputType PSObject).value
    foreach ($domain in $script:TenantOrg.VerifiedDomains) {
        if ($domain.isDefault) {
            $script:TenantDomain = $domain.name
        }
    }
    $oobeSettings = $approfile.outOfBoxExperienceSettings

    # Build up properties
    $json = @{}
    $json.Add("Comment_File", "Profile $($approfile.displayName)")
    $json.Add("Version", 2049)
    $json.Add("ZtdCorrelationId", $approfile.id)
    if ($approfile."@odata.type" -eq "#microsoft.graph.activeDirectoryWindowsAutopilotDeploymentProfile") {
        $json.Add("CloudAssignedDomainJoinMethod", 1)
    }
    else {
        $json.Add("CloudAssignedDomainJoinMethod", 0)
    }
    if ($approfile.deviceNameTemplate) {
        $json.Add("CloudAssignedDeviceName", $approfile.deviceNameTemplate)
    }

    # Figure out config value
    $oobeConfig = 8 + 256
    if ($oobeSettings.userType -eq 'standard') {
        $oobeConfig += 2
    }
    if ($oobeSettings.hidePrivacySettings -eq $true) {
        $oobeConfig += 4
    }
    if ($oobeSettings.hideEULA -eq $true) {
        $oobeConfig += 16
    }
    if ($oobeSettings.skipKeyboardSelectionPage -eq $true) {
        $oobeConfig += 1024
        if ($_.language) {
            $json.Add("CloudAssignedLanguage", $_.language)
            # Use the same value for region so that screen is skipped too
            $json.Add("CloudAssignedRegion", $_.language)
        }
    }
    if ($oobeSettings.deviceUsageType -eq 'shared') {
        $oobeConfig += 32 + 64
    }
    $json.Add("CloudAssignedOobeConfig", $oobeConfig)

    # Set the forced enrollment setting
    if ($oobeSettings.hideEscapeLink -eq $true) {
        $json.Add("CloudAssignedForcedEnrollment", 1)
    }
    else {
        $json.Add("CloudAssignedForcedEnrollment", 0)
    }

    $json.Add("CloudAssignedTenantId", $script:TenantOrg.id)
    $json.Add("CloudAssignedTenantDomain", $script:TenantDomain)
    $embedded = @{}
    $embedded.Add("CloudAssignedTenantDomain", $script:TenantDomain)
    $embedded.Add("CloudAssignedTenantUpn", "")
    if ($oobeSettings.hideEscapeLink -eq $true) {
        $embedded.Add("ForcedEnrollment", 1)
    }
    else {
        $embedded.Add("ForcedEnrollment", 0)
    }
    $ztc = @{}
    $ztc.Add("ZeroTouchConfig", $embedded)
    $json.Add("CloudAssignedAadServerData", (ConvertTo-JSON $ztc -Compress))

    # Skip connectivity check
    if ($approfile.hybridAzureADJoinSkipConnectivityCheck -eq $true) {
        $json.Add("HybridJoinSkipDCConnectivityCheck", 1)
    }

    # Hard-code properties not represented in Intune
    $json.Add("CloudAssignedAutopilotUpdateDisabled", 1)
    $json.Add("CloudAssignedAutopilotUpdateTimeout", 1800000)

    # Return the JSON
    ConvertTo-JSON $json
}