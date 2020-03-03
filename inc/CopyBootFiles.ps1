function CopyBootFiles($iso, $outputfolder) {
    Log "INFO" "Copy Boot Files from $iso to $outputfolder"

    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    Log "DEBUG" "Arch: $architecture"
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    Log "DEBUG" "Sourcefolder: $sourcefolder"
    $destinationfolder = $outputfolder + $sourcefolder
    Log "DEBUG" "Destinationfolder: $destinationfolder"
    $wimBootLatest = 'http://git.ipxe.org/releases/wimboot/wimboot-latest.zip'

    Invoke-WebRequest -Uri $wimBootLatest -OutFile "$tempfolder\wimboot-latest.zip"
    if ($? -eq $true) {
        Log "INFO" "Successfully downloaded $wimBootLatest to $tempfolder"
    } else {
        Log "ERROR" "Failed to download $wimBootLatest to $tempfolder"
    }
    Expand-Archive -Path "$tempfolder\wimboot-latest.zip"  -DestinationPath "$tempfolder\wimboot-latest" -Force
    if ($? -eq $true) {
        Log "INFO" "Successfully expanded $tempfolder\wimboot-latest.zip to $tempfolder\wimboot-latest"
    } else {
        Log "ERROR" "Failed to expand $tempfolder\wimboot-latest.zip to $tempfolder\wimboot-latest"
    }
    Get-ChildItem -Path "$tempfolder\wimboot-latest\*\wimboot" | Copy-Item -Destination "$destinationfolder\wimboot"
    if ($? -eq $true) {
        Log "INFO" "Successfully copied wimboot to $destinationfolder"
    } else {
        Log "ERROR" "Failed to copy wimboot to $destinationfolder"
    }
    Remove-Item "$tempfolder\wimboot-latest*" -Recurse -Force
    if ($? -eq $true) {
        Log "INFO" "Successfully cleaned $tempfolder\wimboot-latest"
    } else {
        Log "ERROR" "Failed to clean $tempfolder\wimboot-latest"
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