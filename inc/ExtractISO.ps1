function ExtractISO($iso, $outputfolder, $overwrite) {
    Log "INFO" "Extracting ISO: $iso..."
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    Log "DEBUG" "Arch: $architecture"
    $outputfolder += $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    Log "DEBUG" "Outputfolder: $outputfolder"
    $dedicated_winpe = "$pwd/winpe/images/$architecture/boot.wim"
    Log "DEBUG" "WinPE search folder: $dedicated_winpe"
    $mount_params = @{ImagePath = $iso; PassThru = $true; ErrorAction = "Ignore"}

    Log "DEBUG" "Mounting ISO: $iso..."
    $mount = Mount-DiskImage @mount_params

    if($mount) {
        Log "DEBUG" "Extracting files from ISO: $iso..."
        Write-Host "`tExtracting ISO for source [" ([System.IO.FileInfo]$iso).Directory.Name "]... " -NoNewLine -ForegroundColor White

        $volume = Get-DiskImage -ImagePath $mount.ImagePath | Get-Volume
        $source = $volume.DriveLetter + ":\"
        New-Item -Force -ItemType directory -Path $outputfolder | Out-Null

        $important_files = @(
            'sources\install.wim',
            'boot\boot.sdi',
            'boot\bcd',
            'bootmgr',
            'bootmgr.efi'
        )

        if (Test-Path $dedicated_winpe -PathType Leaf) {
            $destination_file = $outputfolder + '\sources\boot.wim'
            CopyIfNewer $dedicated_winpe $destination_file
        } else {
            $important_files += 'sources\boot.wim'
        }

        foreach ($important_file in $important_files) {
            $source_file = $source + '\' + $important_file
            $destination_file = $outputfolder + '\' + $important_file

            CopyIfNewer $source_file $destination_file
        }

        Dismount-DiskImage -ImagePath $mount.ImagePath | Out-Null
        Log "INFO" "Copy complete"
        Write-Host "Copy complete" -ForegroundColor Green
    } else {
        Log "ERROR" "Could not mount ISO for source [$([System.IO.FileInfo]$iso).Directory.Name)], check if file is already in use"
        Write-Host "`tERROR: Could not mount ISO for source [" ([System.IO.FileInfo]$iso).Directory.Name "], check if file is already in use" -ForegroundColor Red
    }
}