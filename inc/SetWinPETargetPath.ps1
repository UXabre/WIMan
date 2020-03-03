
function SetWinPETargetPath($wimFile, $targetPath) {
    Log "INFO" "Setting WinPE Targetpath for $wimFile to $targetPath..."
    Dism /Image:"${wimFile}_mount" /Set-TargetPath:"$targetPath" 2>&1> $null
    if ($? -ne 0) {
        Log "INFO" "Successfully set WinPE Targetpath for $wimFile to $targetPath"
        return $true
    } else {
        Log "ERROR" "Failed to set WinPE Targetpath for $wimFile to $targetPath"
        return $false
    }
}