function FinishWIM($wimFile) {
    Log "INFO" "Finishing WIM File $wimFile"
    Dismount-WindowsImage -Path "${wimFile}_mount" -Save -ErrorAction SilentlyContinue
    if ($? -ne 0) {
        Log "INFO" "Successfully finished $wimFile"
        return $true
    } else {
        Log "ERROR" "Failed to finish $wimFile"
        return $false
    }
}
