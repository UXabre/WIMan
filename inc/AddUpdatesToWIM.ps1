function AddUpdatesToWIM($wimFile, $packageFolder) {
    Log "INFO" "Adding updates from $packageFolder to $wimFile"
    Add-WindowsPackage -PackagePath $packageFolder -Path "${wimFile}_mount"

    if ($? -ne 0) {
        Log "INFO" "Successfully added updates from $packageFolder to $wimFile"
        return $true;
    }

    Log "ERROR" "Failed to add updates from $packageFolder to $wimFile"
    return $false;
}