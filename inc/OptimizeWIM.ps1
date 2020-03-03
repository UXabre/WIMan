function OptimizeWIM($wimFile) {
    Log "INFO" "Optimizing WIM File $wimFile"
    DISM /Cleanup-Image /Image="${wimFile}_mount" /StartComponentCleanup /ResetBase  2>&1> $null
    if ($? -ne 0) {
        Log "INFO" "Successfully optimized WIM File $wimFile"
        return $true
    } else {
        Log "ERROR" "Failed to optimize WIM File $wimFile"
        return $false
    }
}