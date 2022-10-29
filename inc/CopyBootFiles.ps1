function CopyBootFiles($iso, $outputfolder) {
    Log "INFO" "Copy Boot Files from $iso to $outputfolder"

    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    Log "DEBUG" "Arch: $architecture"
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    Log "DEBUG" "Sourcefolder: $sourcefolder"
    $destinationfolder = $outputfolder + $sourcefolder
    Log "DEBUG" "Destinationfolder: $destinationfolder"
    $wimBootLatest = "https://github.com/ipxe/wimboot/releases/latest/download/wimboot"

    Invoke-WebRequest -Uri $wimBootLatest -OutFile "$destinationfolder\wimboot"
    if ($? -eq $true) {
        Log "INFO" "Successfully downloaded $wimBootLatest"
    } else {
        Log "ERROR" "Failed to download $wimBootLatest"
    }

    $boot_files = @(
        'boot\boot.sdi',
        'boot\bcd',
        'bootmgr',
        'bootmgr.efi'
    )

    Log "INFO" "Copying remaineder of boot files [$boot_files] to $destinationfolder ..."
    foreach ($boot_file in $boot_files) {
        $source_file = ".\.tmp\" + $sourcefolder + '\' + $boot_file
        $destination_file = $destinationfolder + '\' + $boot_file

        CopyIfNewer $source_file $destination_file
    }
}