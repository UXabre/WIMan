function ConfigureWinPEConsole($wimFile) {
    Log "INFO" "Configuring WinPE console for $wimFile"
    $result = 0

    $Acl = Get-Acl ("${wimFile}_mount\windows\system32\winpe.jpg")
    Log "DEBUG" "ACL for '$($wimFile)_mount\windows\system32\winpe.jpg' is $Acl"
    $result += $?
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
    $result += $?
    $Acl.SetAccessRule($Ar)
    $result += $?
    Set-Acl ("${wimFile}_mount\windows\system32\winpe.jpg") $Acl

    if ($? -eq $true) {
        Log "INFO" "Successfully set ACL for '$($wimFile)_mount\windows\system32\winpe.jpg' to $Acl"
    } else {
        Log "ERROR" "Failed to set ACL for '$($wimFile)_mount\windows\system32\winpe.jpg' to $Acl"
    }

    $result += $?
    CopyIfNewer "$pwd\theme\winPE\winpe.jpg" "${wimFile}_mount\windows\system32\winpe.jpg"
    $result += $?

    Log "DEBUG" "Configuring registry..."
    reg load HKLM\boot.wim_HKCU\ "${wimFile}_mount\windows\system32\config\default" 2>&1> $null
    $result += $?
    reg add HKLM\boot.wim_HKCU\Console\ /v Fullscreen /t REG_DWORD /d 1 /f 2>&1> $null
    $result += $?
    reg add HKLM\boot.wim_HKCU\Console\ /v WindowAlpha /t REG_DWORD /d 180 /f 2>&1> $null
    $result += $?
    reg unload HKLM\boot.wim_HKCU\ 2>&1> $null
    $result += $?
    Log "DEBUG" "Done configuring registry..."

    if ($result -eq 9) {
        Log "INFO" "Successfully configured WinPE Console."
        return $true
    } else {
        Log "ERROR" "Failed to configure WinPE Console!"
        return $false
    }
}