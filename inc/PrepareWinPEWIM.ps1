function PrepareWinPEWIM($iso, $outputfolder) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $originfolder = "$sourcesfolder\$sourcefolder"
    $destinationfolder = $outputfolder + $sourcefolder + '\sources\'
    $bootwim = $tempfolder + $sourcefolder + '\sources\boot.wim'

    New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null
    Log "INFO" "Parsing boot.wim"
    Write-Host "`tParsing boot.wim " -ForegroundColor White
    $metaData = ExtractXMLFromWIM $bootwim
    [array]$wimImages = $metaData.WIM.IMAGE
    $amountOfImages = $wimImages.Length
    Log "INFO" "Found $amountOfImages images!"
    Write-Host "`tFound " $amountOfImages "images!"

    New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null

    if (Test-Path ($destinationfolder + "\" + 'boot.wim') -PathType Leaf) {
        Write-Host "`tDeleting older boot.wim... " -NoNewline -ForegroundColor White
        Remove-Item ($destinationfolder + "\" + 'boot.wim') -Force | Out-Null

        if ($? -ne 0) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    }

    For ($imageIndex=1; $imageIndex -le $amountOfImages; $imageIndex++) {
        $imageName = $wimImages[$imageIndex-1].NAME
        
        Log "INFO" "Extracting [$imageIndex/$amountOfImages] $imageName"
        Write-Host "`tExtracting [$imageIndex/$amountOfImages] " -ForegroundColor White -NoNewLine
        Write-Host "$imageName " -ForegroundColor Yellow -NoNewLine
        
        if (ExtractWIM $bootwim $imageIndex) {
            Write-Host "OK" -ForegroundColor Green
            
            Write-Host -ForegroundColor White "`t`tWriting WinPE overlay... " -NoNewline
            try {
                CopyProtectedFiles "$originfolder\overlays\winpe\" ($tempfolder + $sourcefolder + '\sources\boot.wim_mount\')
                # Copy-Item ".\overlays\winpe\*" -Destination "$tempfolder$sourcefolder\sources\boot.wim_mount\" -Recurse -Force
                Write-Host "OK" -ForegroundColor Green
            } catch {
                Write-Host "Failed" -ForegroundColor Red
            }

            $permanent_packages = "*Microsoft-Windows-WinPE*"
            $all_packages = Get-WindowsPackage -Path "${bootwim}_mount"

            foreach ($package in $all_packages) {
                $package_name = $package.PackageName

                if (!($package_name -like $permanent_packages)) {
                    $short_package = ($package_name -split '~')[0]
                    Write-Host "`t`tRemoving $short_package ... " -NoNewline -ForegroundColor White
                    try {
                        Remove-WindowsPackage -Path "${bootwim}_mount" -PackageName $package_name | Out-Null
                        if ($? -ne 0) {
                            Write-Host "OK" -ForegroundColor Green
                        } else {
                            Write-Host "Failed" -ForegroundColor Red
                        }
                    } catch {
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

            Write-Host "`t`tAdding languages... " -ForegroundColor White -NoNewLine
            $list_languages = Get-ChildItem -Directory -Path "$originfolder\languages\*\" -ErrorAction SilentlyContinue
            if ($list_languages.Count -gt 0 -and $imageName -eq "Microsoft Windows Setup (amd64)") {
                Write-Host
                foreach ($language in $list_languages) {
                    Write-Host "`t`t`tAdding language " -ForegroundColor White -NoNewLine
                    Write-Host $language.Name -ForegroundColor Cyan -NoNewLine
                    Write-Host "... " -ForegroundColor White -NoNewLine

                    if (AddUpdatesToWIM $bootwim "$language\winpe") {
                        Write-Host "OK" -ForegroundColor Green
                    } else {
                        Write-Host "Failed" -ForegroundColor Red
                    }
                }

                Write-Host "`t`t`tGenerating " -ForegroundColor White -NoNewLine
                Write-Host "lang.ini" -ForegroundColor Cyan -NoNewLine
                Write-Host "... " -ForegroundColor White -NoNewLine

                if (GenerateLanguagesIni $bootwim) {
    				Write-Host "OK" -ForegroundColor Green
                } else {
                    Write-Host "Failed" -ForegroundColor Red
                }
            } else {
                Write-Host "Skipping" -ForegroundColor Magenta
            }

            Write-Host "`t`tAdding drivers... " -ForegroundColor White -NoNewLine
            $list_drivers = Get-ChildItem -Directory -Path ".\winpe\drivers\*\" -ErrorAction SilentlyContinue
            if ($list_drivers.Count -gt 0) {
                Write-Host
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
            } else {
                Write-Host "Skipping" -ForegroundColor Magenta
            }

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

            Write-Host "`t`tExporting boot.wim... " -NoNewline -ForegroundColor White
            if (ExportWIMIndex $bootwim ($destinationfolder + "\" + 'boot.wim') $imageIndex) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}