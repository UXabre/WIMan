function PrepareInstallWIM($iso, $outputfolder) {
	Log "INFO" "Preparing installation WIM..."

	$architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
	Log "DEBUG" "Arch: $architecture"
	$sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
	Log "DEBUG" "Sourcefolder: $sourcefolder"
	$destinationfolder = $outputfolder + $sourcefolder + '\sources\'
	Log "DEBUG" "Destinationfolder: $destinationfolder"
    $installwim = $tempfolder + $sourcefolder + '\sources\install.wim'
	Log "DEBUG" "Original WIM: $installwim"

    $metaData = ExtractXMLFromWIM $installwim
    [array]$wimImages = $metaData.WIM.IMAGE
    $amountOfImages = $wimImages.Length
    Log "INFO" "Found $amountOfImages images!"
    Write-Host "`tFound " $amountOfImages "images!"

    New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null
    Remove-Item -Force -Path "$destinationfolder\images.ini" -ErrorAction SilentlyContinue

    $oldImages = Get-ChildItem -Path ($destinationfolder + "\*.wim") -Exclude "boot.wim" -ErrorAction SilentlyContinue
    foreach ($oldImage in $oldImages) {
		Log "INFO" "Deleting older $($oldImage.Name)..."
        Write-Host "`t`tDeleting older $($oldImage.Name)... " -NoNewline -ForegroundColor White
        Remove-Item $oldImage -Force | Out-Null

        if ($? -ne 0) {
			Log "INFO" "Successfully deleted older $($oldImage.Name)"
            Write-Host "OK" -ForegroundColor Green
        } else {
			Log "ERROR" "Failed to delete older $($oldImage.Name)"
            Write-Host "Failed" -ForegroundColor Red
        }
    }

    For ($imageIndex=1; $imageIndex -le $amountOfImages; $imageIndex++) {
        $imageName = $wimImages[$imageIndex-1].NAME
        $fileName = $imageName

        if ($Optimization -eq 1) {
            $fileName = $wimImages[$imageIndex-1].WINDOWS.INSTALLATIONTYPE + ".wim"
        } elseif ($Optimization -eq 2) {
            $fileName = $wimImages[$imageIndex-1].WINDOWS.EDITIONID + ".wim"
        } elseif ($Optimization -eq 3) {
            $fileName = "install.wim"
        }

		Log "INFO" "Extracting [$imageIndex/$amountOfImages] $imageName"
		Write-Host "`tExtracting [$imageIndex/$amountOfImages] " -ForegroundColor White -NoNewLine
        Write-Host "$imageName " -ForegroundColor Yellow -NoNewLine
        if (ExtractWIM $installwim $imageIndex) {
			Log "INFO" "Successfully extracted [$imageIndex/$amountOfImages] $imageName"
            Write-Host "OK" -ForegroundColor Green

			Log "INFO" "Adding drivers..."
            Write-Host "`t`tAdding drivers... " -ForegroundColor White -NoNewLine
            $list_drivers = Get-ChildItem -Directory -Path "$sourcesfolder$sourcefolder\drivers\*\" -ErrorAction SilentlyContinue
			if ($list_drivers.Count -gt 0) {
				Write-Host
				foreach ($driver in $list_drivers) {
					Log "INFO" "Adding driver $($driver.Name)..."
					Write-Host "`t`t`tAdding driver " -ForegroundColor White -NoNewLine
					Write-Host $driver.Name -ForegroundColor Cyan -NoNewLine
					Write-Host "... " -ForegroundColor White -NoNewLine

					if (AddDriversToWIM $installwim $driver) {
						Log "INFO" "Successfully added driver $($driver.Name)"
						Write-Host "OK" -ForegroundColor Green
					} else {
						Log "ERROR" "Failed to add driver $($driver.Name)"
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			} else {
				Log "WARN" "Skipping driver $($driver.Name)"
				Write-Host "Skipping" -ForegroundColor Magenta
			}

			Log "INFO" "Adding updates..."
            Write-Host "`t`tAdding updates... " -ForegroundColor White -NoNewLine
            $list_updates = Get-ChildItem -Path "$sourcesfolder\$sourcefolder\updates\*" -include *.cab, *.msu  -ErrorAction SilentlyContinue

			if ($list_updates.Count -gt 0) {
				Write-Host

				foreach ($update in $list_updates) {
					$updatefile = $update
					if ($update.Extension -eq ".msu") {
						Log "INFO" "Extracting update $($update.BaseName)..."
						Write-Host "`t`t`tExtracting update " -ForegroundColor White -NoNewLine
						Write-Host $update.BaseName -ForegroundColor Cyan -NoNewLine
						Write-Host "... " -ForegroundColor White -NoNewLine

						New-Item -Force -ItemType directory -Path ($update.Directory.FullName + $update.BaseName) | Out-Null
						expand -F:*.cab $update ($update.Directory.FullName + $update.BaseName) | Out-Null
						Remove-Item -Recurse -Force ($update.Directory.FullName + $update.BaseName + "\wsusscan.cab")

						if ($? -ne 0) {
							Log "INFO" "Successfully extracted update $($update.BaseName)"
							Write-Host "OK" -ForegroundColor Green
						} else {
							Log "ERROR" "Failed to extract update $($update.BaseName)"
							Write-Host "Failed" -ForegroundColor Red
						}

						$embedded_updates = Get-ChildItem -Path ($update.Directory.FullName + $update.BaseName + "\*.cab")
						foreach ($embedded_update in $embedded_updates) {
							$embedded_updateInfo = Get-WindowsPackage -PackagePath $embedded_update -Path ($installwim + "_mount")

							Log "INFO" "Adding update $($embedded_updateInfo.Description)"
							Write-Host "`t`t`t`tAdding update " -ForegroundColor White -NoNewLine
							Write-Host $embedded_updateInfo.Description -ForegroundColor Cyan -NoNewLine
							Write-Host "... " -ForegroundColor White -NoNewLine

							if (($embedded_updateInfo.PackageState -ne "Installed") -and ($embedded_updateInfo.Applicable -eq $true)) {
								if (AddUpdatesToWIM $installwim $embedded_update) {
									Log "INFO" "Successfully added update $($embedded_updateInfo.Description)"
									Write-Host "OK" -ForegroundColor Green
								} else {
									Log "ERROR" "Failed to add update $($embedded_updateInfo.Description)"
									Write-Host "Failed" -ForegroundColor Red
								}
							} else {
								Log "WARN" "Skipping update $($embedded_updateInfo.Description)"
								Write-Host "Skipping" -ForegroundColor Magenta
							}
						}

						Log "INFO" "Cleaning update $($update.BaseName)..."
						Write-Host "`t`t`tCleaning update " -ForegroundColor White -NoNewLine
						Write-Host $update.BaseName -ForegroundColor Cyan -NoNewLine
						Write-Host "... " -ForegroundColor White -NoNewLine

						Remove-Item -Recurse -Force ($update.Directory.FullName + $update.BaseName)

						if ($? -ne 0) {
							Log "INFO" "Cleaned update $($update.BaseName)"
							Write-Host "OK" -ForegroundColor Green
						} else {
							Log "ERROR" "Failed to clean update $($update.BaseName)"
							Write-Host "Failed" -ForegroundColor Red
						}
					} elseif ($update.Extension -eq ".cab") {
						$embedded_updateInfo = Get-WindowsPackage -PackagePath $updatefile -Path ($installwim + "_mount")

						Log "INFO" "Adding update $($embedded_updateInfo.Name)..."
						Write-Host "`t`t`tAdding update " -ForegroundColor White -NoNewLine
						Write-Host $embedded_updateInfo.Name -ForegroundColor Cyan -NoNewLine
						Write-Host "... " -ForegroundColor White -NoNewLine

						if ($embedded_updateInfo.State == "NotInstalled") {
							if (AddUpdatesToWIM $installwim $updatefile) {
								Log "INFO" "Successfully installed update $($embedded_updateInfo.Name)..."
								Write-Host "OK" -ForegroundColor Green
							} else {
								Log "ERROR" "Failed to install update $($embedded_updateInfo.Name)..."
								Write-Host "Failed" -ForegroundColor Red
							}
						} else {
							Log "WARN" "Skipping update $($embedded_updateInfo.Name)..."
							Write-Host "Skipping" -ForegroundColor Magenta
						}
					}
				}
			} else {
				Log "WARN" "Skipping update installation"
				Write-Host "Skipping" -ForegroundColor Magenta
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

            Write-Host "`t`tExporting '$imageName'..." -NoNewline -ForegroundColor White
            if (ExportWIMIndex $installwim ($destinationfolder + "\$fileName") $imageIndex) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }

			Log "INFO" "Writing entry to images.ini..."
            Write-Host "`t`tWriting entry to images.ini... " -ForegroundColor White -NoNewLine
			$INITemplate = "$imageName=$fileName"
            Add-Content "$destinationfolder\images.ini" $INITemplate
            Write-Host "OK" -ForegroundColor Green
        } else {
			Log "ERROR" "Failed to install updates"
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}