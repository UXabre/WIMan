function PrepareWIM($wimFile) {
    Log "INFO" "Preparing WIM File $wimFile"
    Log "INFO" "Unloading registry hive HKLM\boot.wim_HKCU\"
    reg unload HKLM\boot.wim_HKCU\ 2>&1> $null

    Log "INFO" "Removing Read-Only flag"
    Set-ItemProperty "$wimFile" -name IsReadOnly -value $false

    try {
        Log "INFO" "Dismounting previously mounted WIM file"
        Dismount-WindowsImage -Path "${wimFile}_mount" -Discard -ErrorAction SilentlyContinue
        Log "INFO" "Dismounted WIM file"
    } catch {
        Log "WARN" "Failed to dismount previously mounted WIM file $wimFile probably not mounted..."
    }
}