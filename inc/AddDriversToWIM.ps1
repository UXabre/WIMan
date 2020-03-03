function AddDriversToWIM($wimFile, $driverFolder) {
    Log "INFO" "Adding drivers from $driverFolder to $wimFile"
    Add-WindowsDriver -Path "${wimFile}_mount" -Driver $driverFolder -Recurse -ForceUnsigned

    if ($? -ne 0) {
        Log "INFO" "Successfully added drivers from $driverFolder to $wimFile"
        return $true;
    }

    Log "ERROR" "Failed to add drivers from $driverFolder to $wimFile"
    return $false;
}