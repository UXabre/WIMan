param([string]$sourcefolder = "$pwd\sources\", [string]$outputfolder = "$pwd\finalized\", [string]$tempfolder = "$pwd\.tmp\")
Set-ExecutionPolicy Bypass -Scope Process -Force

function Copy-If-Newer($source_file, $destination_file) {
    New-Item -Force -ItemType directory -Path ([System.IO.FileInfo]$destination_file).Directory.FullName | Out-Null
    if ( !(Test-Path $destination_file -PathType Leaf) -or
            (( ([System.IO.FileInfo]$source_file).LastWriteTime -gt ([System.IO.FileInfo]$destination_file).LastWriteTime ) -and
            ( ([System.IO.FileInfo]$source_file).Length -ne ([System.IO.FileInfo]$destination_file).Length )
            )
        ) {
	    Copy-Item $source_file -Destination $destination_file | Out-Null
    }
}

function ExtractISO($iso, $outputfolder, $overwrite) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $outputfolder += $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $dedicated_winpe = "$pwd/winpe/images/$architecture/boot.wim"
    $mount_params = @{ImagePath = $iso; PassThru = $true; ErrorAction = "Ignore"}
    $mount = Mount-DiskImage @mount_params

    if($mount) {
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
            Copy-If-Newer $dedicated_winpe $destination_file
        } else {
            $important_files += 'sources\boot.wim'
        }

        foreach ($important_file in $important_files) {
            $source_file = $source + '\' + $important_file
            $destination_file = $outputfolder + '\' + $important_file

            Copy-If-Newer $source_file $destination_file
        }

        Dismount-DiskImage -ImagePath $mount.ImagePath | Out-Null
        Write-Host "Copy complete" -ForegroundColor Green
    } else {
        Write-Host "`tERROR: Could not mount ISO for source [" ([System.IO.FileInfo]$iso).Directory.Name "], check if file is already in use" -ForegroundColor Red
    }
}

function PrepareWIM($wimFile) {
    reg unload HKLM\boot.wim_HKCU\ 2>&1> $null
    Set-ItemProperty "$wimFile" -name IsReadOnly -value $false
    Dism /Unmount-Image /MountDir:"${wimFile}_mount" /Discard 2>&1> $null
}

function ExportWIMIndex($wimFile, $exportedWimFile, $index) {
    if (Test-Path "$exportedWimFile" -PathType Leaf) {
        Remove-Item "$exportedWimFile" -Force | Out-Null
    }

    Dism /Export-Image /SourceImageFile:"$wimFile" /SourceIndex:$index /DestinationImageFile:"$exportedWimFile" /Compress:max /Bootable 2>&1> $null
    if ($? -ne 0) {
        return $true
    } else {
        return $false
    }
}

function ExtractWIM($wimFile, $index) {
    PrepareWIM $wimFile

    if (Test-Path "${wimFile}_mount/" -PathType Leaf) {
        Remove-Item "${wimFile}_mount/" -Recurse -Force | Out-Null
    }

    New-Item -ItemType directory -Path "${wimFile}_mount/" -Force | Out-Null

    #Dism /Mount-Image /ImageFile:"$wimFile" /index:1 /MountDir:"${wimFile}_mount"
    Mount-WindowsImage -ImagePath "$wimFile" -Index 1 -Path "${wimFile}_mount" -Optimize

    if ($? -ne 0) { return $true; }
    return $false;
}

function OptimizeWIM($wimFile) {
    DISM /Cleanup-Image /Image="${wimFile}_mount" /StartComponentCleanup /ResetBase  2>&1> $null
    if ($? -ne 0) {
        return $true
    } else {
        return $false
    }
}

function SetWinPETargetPath($wimFile, $targetPath) {
    Dism /Image:"${wimFile}_mount" /Set-TargetPath:"$targetPath" 2>&1> $null
    if ($? -ne 0) {
        return $true
    } else {
        return $false
    }
}

function FinishWIM($wimFile) {
    Dism /Unmount-Image /MountDir:"${wimFile}_mount" /Commit 2>&1> $null
    if ($? -ne 0) {
        return $true
    } else {
        return $false
    }
}

function ConfigureWinPEConsole($wimFile) {
    $result = 0

    $Acl = Get-Acl ("${wimFile}_mount\windows\system32\winpe.jpg")
    $result += $?
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
    $result += $?
    $Acl.SetAccessRule($Ar)
    $result += $?
    Set-Acl ("${wimFile}_mount\windows\system32\winpe.jpg") $Acl
    $result += $?
    Copy-Item "$pwd\theme\winPE\winpe.jpg" -Destination "${wimFile}_mount\windows\system32\winpe.jpg" -Force | Out-Null
    $result += $?

    reg load HKLM\boot.wim_HKCU\ "${wimFile}_mount\windows\system32\config\default" 2>&1> $null
    $result += $?
    reg add HKLM\boot.wim_HKCU\Console\ /v Fullscreen /t REG_DWORD /d 1 /f 2>&1> $null
    $result += $?
    reg add HKLM\boot.wim_HKCU\Console\ /v WindowAlpha /t REG_DWORD /d 180 /f 2>&1> $null
    $result += $?
    reg unload HKLM\boot.wim_HKCU\ 2>&1> $null
    $result += $?

    if ($result -eq 9) {
        return $true
    } else {
        return $false
    }
}

function AddDriversToWIM($wimFile, $driverFolder) {
    Dism /Image:"${wimFile}_mount" /Add-Driver /Driver:$driverFolder /recurse /ForceUnsigned

    if ($? -ne 0) { return $true; }
    return $false;
}

function AddUpdatesToWIM($wimFile, $packageFolder) {
    # $list_isos = Get-ChildItem -Path "$sourcefolder\*\*\*.iso"

    Dism /Image:"${wimFile}_mount" /Add-Package /PackagePath:$packageFolder /recurse

    if ($? -ne 0) { return $true; }
    return $false;
}

function ExtractXMLFromWIM($wimfile) {
    $rawWIM = [System.IO.File]::OpenRead($wimfile)

    $rawWIM.seek(0x50,0)
    $bytes = New-Object -TypeName Byte[] -ArgumentList 8
    $rawWIM.read($bytes,0,$bytes.Length)
    $xmlSize = $rawWIM.Length - [System.BitConverter]::toInt64($bytes, 0) - 2
    $position = $rawWIM.seek(-$xmlSize,'END')
    $bytes = New-Object -TypeName Byte[] -ArgumentList $xmlSize
    $rawWIM.read($bytes,0,$bytes.Length)

    $rawWIM.Close()
    [xml]$result = [System.Text.Encoding]::Unicode.getString($bytes, 0, $bytes.Length)
    return $result
}

function CopyBootFiles($iso, $outputfolder) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $destinationfolder = $outputfolder + $sourcefolder
    $wimBootLatest = 'http://git.ipxe.org/releases/wimboot/wimboot-latest.zip'
    Invoke-WebRequest -Uri $wimBootLatest -OutFile "$tempfolder\wimboot-latest.zip"
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$tempfolder\wimboot-latest.zip", "$tempfolder\wimboot-latest")

    Get-ChildItem -Path "$tempfolder\wimboot-latest\*\wimboot" | Copy-Item -Destination "$destinationfolder\wimboot"

    Remove-Item "$tempfolder\wimboot-latest*" -Recurse -Force

    $boot_files = @(
        'boot\boot.sdi',
        'boot\bcd',
        'bootmgr',
        'bootmgr.efi'
    )

    foreach ($boot_file in $boot_files) {
        $source_file = ".\.tmp\" + $sourcefolder + '\' + $boot_file
        $destination_file = $destinationfolder + '\' + $boot_file

        Copy-If-Newer $source_file $destination_file
    }
}

function PrepareInstallWIM($iso, $outputfolder) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $destinationfolder = $outputfolder + $sourcefolder + '\sources\'
    $installwim = $tempfolder + $sourcefolder + '\sources\install.wim'

    $metaData = ExtractXMLFromWIM $installwim
    $amountOfImages = $metaData.WIM.IMAGE.Length
    Write-Host "`tFound " $amountOfImages "images!"

    For ($imageIndex=1; $imageIndex -le $amountOfImages; $imageIndex++) {
        $imageName = $metaData.WIM.IMAGE[$imageIndex-1].NAME

        Write-Host "`tExtracting [$imageIndex/$amountOfImages] " -ForegroundColor White -NoNewLine
        Write-Host "$imageName " -ForegroundColor Yellow -NoNewLine
        if (ExtractWIM $installwim $imageIndex) {
            Write-Host "OK" -ForegroundColor Green

            Write-Host "`t`tAdding drivers... " -ForegroundColor White
            $list_drivers = Get-ChildItem -Directory -Path "$tempfolder$sourcefolder\drivers\*\"
            foreach ($driver in $list_drivers) {
                Write-Host "`t`tAdding driver $driver... " -ForegroundColor White
                if (AddDriversToWIM $installwim "$tempfolder$sourcefolder\drivers") {
                    Write-Host "OK" -ForegroundColor Green
                } else {
                    Write-Host "Failed" -ForegroundColor Red
                }
            }

            Write-Host "`t`tAdding updates... " -NoNewline -ForegroundColor White
            if (AddUpdatesToWIM $installwim "$tempfolder$sourcefolder\updates") {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }

            Write-Host -ForegroundColor White "`t`tOptimizing image... " -NoNewline
            if (OptimizeWIM $installwim) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }

            Write-Host -ForegroundColor White "`t`tCommiting changes... " -NoNewline
            if (FinishWIM $installwim) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }

            New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null

            Write-Host "`t`tExporting '$imageName'..." -NoNewline -ForegroundColor White
            if (ExportWIMIndex $installwim ($destinationfolder + "\$imageName.wim") $imageIndex) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}

function PrepareWinPEWIM($iso, $outputfolder) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $destinationfolder = $outputfolder + $sourcefolder + '\sources\'
    $bootwim = $tempfolder + $sourcefolder + '\sources\boot.wim'

    Write-Host "`tExtracting boot.wim " -ForegroundColor White -NoNewline
    if (ExtractWIM $bootwim 1) {
        Write-Host "OK" -ForegroundColor Green
        # Do magic here!

        Copy-Item ".\winpe\overlay\*" -Destination ($tempfolder + $sourcefolder + '\sources\boot.wim_mount\') -Recurse -Force | Out-Null

        $permanent_packages = "*Microsoft-Windows-WinPE*"
        $all_packages = Get-WindowsPackage -Path "${bootwim}_mount"

        foreach ($package in $all_packages) {
            $package_name = $package.PackageName

            if (!($package_name -like $permanent_packages)) {
                $short_package = ($package_name -split '~')[0]
                Write-Host "`t`tRemoving $short_package ... " -NoNewline -ForegroundColor White
                DISM /Image:"${bootwim}_mount" /Remove-Package /PackageName:$package_name 2>&1> $null
                if ($? -ne 0) {
                    Write-Host "OK" -ForegroundColor Green
                } else {
                    Write-Host "Failed" -ForegroundColor Red
                }
            }
        }

        Write-Host "`t`tConfiguring WinPE Console... " -NoNewline -ForegroundColor White
        if (ConfigureWinPEConsole $bootwim) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }

        Write-Host "`t`tAdding drivers... " -ForegroundColor White
        $list_drivers = Get-ChildItem -Directory -Path ".\winpe\drivers\*\"
        foreach ($driver in $list_drivers) {
            Write-Host "`t`t`tAdding driver " -ForegroundColor White -NoNewLine
            Write-Host $driver.Name -ForegroundColor Cyan -NoNewLine
            Write-Host "... " -ForegroundColor White -NoNewLine

            if (AddDriversToWIM $bootwim $driver) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }
        }

        # Write-Host "`t`tAdding drivers... " -NoNewline -ForegroundColor White
        # if (AddDriversToWIM $bootwim ".\winpe\drivers") {
        #     Write-Host "OK" -ForegroundColor Green
        # } else {
        #     Write-Host "Failed" -ForegroundColor Red
        # }

        Write-Host -ForegroundColor White "`t`tSetting TargetPath to X:... " -NoNewline
        if (SetWinPETargetPath $bootwim "X:\") {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }

        Write-Host -ForegroundColor White "`t`tOptimizing image... " -NoNewline
        if (OptimizeWIM $bootwim) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }

        Write-Host -ForegroundColor White "`t`tCommiting changes... " -NoNewline
        if (FinishWIM $bootwim) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }

        New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null

        Write-Host "`t`tExporting boot.wim... " -NoNewline -ForegroundColor White
        if (ExportWIMIndex $bootwim ($destinationfolder + "\" + 'boot.wim') 1) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed" -ForegroundColor Red
    }
}

# MAIN starts here!

$DedicatedWimFiles = Get-ChildItem -Recurse ".\winpe\images\*\boot.wim"

if ( ($DedicatedWimFiles | Measure-Object | ForEach-Object{$_.Count}) -gt 0 ) {
    Write-Host "Found" ($DedicatedWimFiles | Measure-Object | ForEach-Object{$_.Count}) "dedicated winpe.wim file(s)!" -ForegroundColor White
} else {
    $install_WAIK_winpe = Read-Host "No dedicated winpe.wim file found, we can fetch this automatically for you but this takes a few minutes. `nDo you want to continue? (Y/N)"

    if ($install_WAIK_winpe -eq 'n') {
        Write-Host "Will use the embedded winpe file from windows installation media. This is a slightly larger file with additional features that you might not need or want. This is only a convenience rather than a solution!" -ForegroundColor White
    } else {
        try {
            Get-Command "choco" | Out-Null
        } catch {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }

        choco install windows-adk-winpe -y --installargs="/installPath `"$pwd\.tmp\wadk-winpe\`""

        if ($? -ne 0) {
            Write-Host "Successfully installed WAIK-WINPE" -ForegroundColor Green
            $wim_boot_files = Get-ChildItem -Path ".\.tmp\wadk-winpe\*\winpe.wim" -Recurse
            foreach($wim_boot_file in $wim_boot_files){
                $architecture = $wim_boot_file.Directory.Parent.Name
                Write-Host $wim_boot_file $architecture
                New-Item -Force -ItemType directory -Path ".\winpe\images\$architecture\" | Out-Null
                Move-Item "$wim_boot_file" ".\winpe\images\$architecture\boot.wim"
            }
        } else {
            Write-Host "Failed installing WAIK-WINPE. Install it manually and copy the winpe.wim file to .\winpe." -ForegroundColor Red
            Exit -1
        }
    }
}

function DetectWindowsName($iso) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $destinationfolder = $outputfolder + $sourcefolder + '\sources\'
    $installwim = $tempfolder + $sourcefolder + '\sources\install.wim'

    $metaData = ExtractXMLFromWIM $installwim
    $windowsBase = $metaData.WIM.IMAGE[0].NAME.Substring(0, $metaData.WIM.IMAGE[0].NAME.LastIndexOf(' '))
    Write-Host "`tDetected " -NoNewLine
    Write-Host "$windowsBase" -ForegroundColor Yellow
}

$OriginalPref = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

$folder = New-Item -Force -ItemType directory -Path $tempfolder
$folder.Attributes += 'HIDDEN'

$list_isos = Get-ChildItem -Path "$sourcefolder\*\*\*.iso"

foreach($iso in $list_isos){
    Write-Host "Building media for " $iso.Directory.Name "[" $iso.Directory.Parent.Name "]"
    ExtractISO $iso $tempfolder $overwrite

    DetectWindowsName $iso

    PrepareWinPEWIM $iso $outputfolder
   # PrepareInstallWIM $iso $outputfolder

    Write-Host "`tCopying boot files... " -NoNewline -ForegroundColor White
    CopyBootFiles $iso $outputfolder
    Write-Host "OK" -ForegroundColor Green
}

Write-Host "All Done!"
$ProgressPreference = $OriginalPref