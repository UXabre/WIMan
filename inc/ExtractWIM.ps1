function ExtractWIM($wimFile, $index) {
    Log "INFO" "Extracting WIM image $wimFile, Index $index"
    PrepareWIM $wimFile

    Log "DEBUG" "Test if mount directory [${wimFile}_mount/] still exists"
    if (Test-Path "${wimFile}_mount/" -PathType Leaf) {
        Remove-Item "${wimFile}_mount/" -Recurse -Force | Out-Null

        if ($? -eq $true) {
            Log "DEBUG" "Successfully deleted mount directory [${wimFile}_mount/]"
        } else {
            Log "ERROR" "Failed to delet mount directory [${wimFile}_mount/]"
        }
    }

    Log "DEBUG" "Creating mount directory [${wimFile}_mount/]"
    New-Item -ItemType directory -Path "${wimFile}_mount/" -Force | Out-Null
    Log "INFO" "Mounting WIM Image $wimFile (Index: $index) => [${wimFile}_mount/]..."
    Mount-WindowsImage -ImagePath "$wimFile" -Index $index -Path "${wimFile}_mount" -Optimize

    if ($? -ne 0) {
        Log "INFO" "Successfully mounted WIM Image $wimFile (Index: $index) => [${wimFile}_mount/]"
        return $true;
    }

    Log "ERROR" "Failed to mount WIM Image $wimFile (Index: $index) => [${wimFile}_mount/]"
    return $false;
}