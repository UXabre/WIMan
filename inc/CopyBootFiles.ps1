function CopyBootFiles($iso, $outputfolder) {
    Log "INFO" "Copy Boot Files from $iso to $outputfolder"

    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    Log "DEBUG" "Arch: $architecture"
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    Log "DEBUG" "Sourcefolder: $sourcefolder"
    $destinationfolder = $outputfolder + $sourcefolder
    Log "DEBUG" "Destinationfolder: $destinationfolder"
    $WimbootVersion = "v2.9.0"
    $WimbootHash = "5f067ccdc4d084d5bf77b6c853bd0f8402dfc2b4cd1b103d358993ae97fae8e3"
    $WimbootUrl = "https://github.com/ipxe/wimboot/releases/download/$WimbootVersion/wimboot"
    $WimbootCache = ".tmp\wimboot\$WimbootVersion\wimboot"

    if (Test-Path $WimbootCache -PathType Leaf) {
        Log "INFO" "Wimboot $WimbootVersion found in cache, skipping download"
    } else {
        Log "INFO" "Downloading wimboot $WimbootVersion from $WimbootUrl"
        New-Item -Force -ItemType directory -Path ([System.IO.FileInfo]$WimbootCache).Directory.FullName | Out-Null
        Invoke-WebRequest -Uri $WimbootUrl -OutFile $WimbootCache
        if ($? -ne $true) {
            Log "ERROR" "Failed to download wimboot from $WimbootUrl"
            return
        }
    }

    $actualHash = (Get-FileHash -Path $WimbootCache -Algorithm SHA256).Hash
    if ($actualHash -ne $WimbootHash) {
        Log "ERROR" "Wimboot SHA256 mismatch: expected $WimbootHash, got $actualHash"
        Remove-Item $WimbootCache -Force
        return
    }

    $destFile = "$destinationfolder\wimboot"
    New-Item -Force -ItemType directory -Path ([System.IO.FileInfo]$destFile).Directory.FullName | Out-Null
    Copy-Item $WimbootCache -Destination $destFile -Force
    Log "INFO" "Wimboot $WimbootVersion deployed to $destFile (SHA256 verified)"

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