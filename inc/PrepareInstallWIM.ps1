function PrepareInstallWIM($iso, $outputfolder, $optimization=1) {
	Log "INFO" "Preparing installation WIM..."

	$architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
	Log "DEBUG" "Arch: $architecture"
	$sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
	Log "DEBUG" "Sourcefolder: $sourcefolder"
	$destinationfolder = $outputfolder + $sourcefolder + '\sources\'
	Log "DEBUG" "Destinationfolder: $destinationfolder"

	$searchFolders = @("$tempfolder$sourcefolder\sources\install.wim", "$pwd\sources\$architecture\$(([System.IO.FileInfo]$iso).Directory.Name)\images\*")
	$installwims = foreach ($searchfolder in $searchFolders) {
		Get-ChildItem $searchFolder -include "*.wim"
	}

	New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null
	Remove-Item -Force -Path "$destinationfolder\images.ini" -ErrorAction SilentlyContinue

	$oldImages = Get-ChildItem -Path ($destinationfolder + "\*.wim") -Exclude "boot.wim" -ErrorAction SilentlyContinue
	foreach ($oldImage in $oldImages) {
		Log "INFO" "Deleting older $($oldImage.Name)..."
		Write-Host "`tDeleting older $($oldImage.Name)... " -NoNewline -ForegroundColor White
		Remove-Item $oldImage -Force | Out-Null

		if ($? -ne 0) {
			Log "INFO" "Successfully deleted older $($oldImage.Name)"
			Write-Host "OK" -ForegroundColor Green
		} else {
			Log "ERROR" "Failed to delete older $($oldImage.Name)"
			Write-Host "Failed" -ForegroundColor Red
		}
	}

	foreach ($installwim in $installwims) {
		Log "DEBUG" "Parsing WIM: $installwim"
		Write-Host "`tParsing WIM: $installwim"

		$metaData = ExtractXMLFromWIM $installwim
		[array]$wimImages = $metaData.WIM.IMAGE
		$amountOfImages = $wimImages.Length
		Log "INFO" "Found $amountOfImages images!"
		Write-Host "`t`tFound " $amountOfImages "images!"


		For ($imageIndex=1; $imageIndex -le $amountOfImages; $imageIndex++) {
			$imageName = $wimImages[$imageIndex-1].NAME
			$fileName = $imageName

			if ($optimization -eq 1) {
				$fileName = $wimImages[$imageIndex-1].WINDOWS.INSTALLATIONTYPE + ".wim"
			} elseif ($optimization -eq 2) {
				$fileName = $wimImages[$imageIndex-1].WINDOWS.EDITIONID + ".wim"
			} elseif ($optimization -eq 3) {
				$fileName = "install.wim"
			}

			Log "INFO" "Extracting [$imageIndex/$amountOfImages] $imageName"
			Write-Host "`t`tExtracting [$imageIndex/$amountOfImages] " -ForegroundColor White -NoNewLine
			Write-Host "$imageName " -ForegroundColor Yellow -NoNewLine
			if (ExtractWIM $installwim $imageIndex) {
				Log "INFO" "Successfully extracted [$imageIndex/$amountOfImages] $imageName"
				Write-Host "OK" -ForegroundColor Green

				Log "INFO" "Adding drivers..."
				Write-Host "`t`t`tAdding drivers... " -ForegroundColor White -NoNewLine
				$list_drivers = Get-ChildItem -Directory -Path "$sourcesfolder$sourcefolder\drivers\*\" -ErrorAction SilentlyContinue
				if ($list_drivers.Count -gt 0) {
					Write-Host
					foreach ($driver in $list_drivers) {
						Log "INFO" "Adding driver $($driver.Name)..."
						Write-Host "`t`t`t`tAdding driver " -ForegroundColor White -NoNewLine
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
				Write-Host "`t`t`tAdding updates... " -ForegroundColor White -NoNewLine
				$list_updates = Get-ChildItem -Path "$sourcesfolder\$sourcefolder\updates\*" -include *.cab, *.msu  -ErrorAction SilentlyContinue

				if ($list_updates.Count -gt 0) {
					Write-Host

					foreach ($update in $list_updates) {
						$updatefile = $update
						if ($update.Extension -eq ".msu") {
							Log "INFO" "Extracting update $($update.BaseName)..."
							Write-Host "`t`t`t`tExtracting update " -ForegroundColor White -NoNewLine
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
								Write-Host "`t`t`t`t`tAdding update " -ForegroundColor White -NoNewLine
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
							Write-Host "`t`t`t`tCleaning update " -ForegroundColor White -NoNewLine
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
							Write-Host "`t`t`t`tAdding update " -ForegroundColor White -NoNewLine
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

				Log "INFO" "Adding appxs..."
				Write-Host "`t`t`tAdding appxs... " -ForegroundColor White -NoNewLine
				$list_apps = Get-ChildItem -Directory -Path "$sourcesfolder$sourcefolder\apps\*\" -ErrorAction SilentlyContinue

				if ($list_apps.Count -gt 0) {
					Write-Host
					foreach ($app in $list_apps) {
						Log "INFO" "Adding app $($app.Name)..."
						Write-Host "`t`t`t`tAdding app " -ForegroundColor White -NoNewLine
						Write-Host $app.Name -ForegroundColor Cyan -NoNewLine
						Write-Host "... " -ForegroundColor White -NoNewLine

						$apps_folders = @("$sourcesfolder\$sourcefolder\apps\$($app.Name)\*", "$sourcesfolder\$sourcefolder\apps\$($app.Name)\dependencies\x64\*")
						$apps_to_install = foreach ($app_folder in $apps_folders) {
							Get-ChildItem -File $app_folder
						} 
						$apps_to_install = $apps_to_install | where { $_.extension -in (".appx", ".msixbundle") }

						foreach ($app_to_install in $apps_to_install) {
							if (Add-AppxProvisionedPackage -Path "${installwim}_mount" -SkipLicense -PackagePath "$app_to_install") {
								Log "INFO" "Successfully added app $($app_to_install.Name)"
								Write-Host "OK" -ForegroundColor Green
							} else {
								Log "ERROR" "Failed to add app $($app_to_install.Name)"
								Write-Host "Failed" -ForegroundColor Red
							}
						}
					}
				} else {
					Log "WARN" "Skipping app installation as none found"
					Write-Host "Skipping" -ForegroundColor Magenta
				}

				Write-Host "`t`t`tAdding languages... " -ForegroundColor White -NoNewLine
				$list_languages = Get-ChildItem -Directory -Path "$sourcesfolder\$sourcefolder\languages\*\" -ErrorAction SilentlyContinue
				if ($list_languages.Count -gt 0) {
					Write-Host
					foreach ($language in $list_languages) {
						Write-Host "`t`t`t`tAdding language " -ForegroundColor White -NoNewLine
						Write-Host $language.Name -ForegroundColor Cyan -NoNewLine
						Write-Host "... " -ForegroundColor White
	
						$packages = Get-WindowsPackage -path "${installwim}_mount"
						$packages = $packages | % { if ( $_.PackageState -eq "Installed" -and $_.PackageName -match '^([\w-]*~[\w-]*~[\w-]*).*$' ) { $matches[1] } } | Get-Unique

						$packages = $packages | % {
							Get-ChildItem -Path "$language" -Filter "$_*"
						}

						$packages += $(Get-ChildItem -path $language "Microsoft-Windows-Client-Language-Pack_x64_*.cab")

						for ($i = 0; $i -lt $packages.Count; $i++) {
							if (AddUpdatesToWIM "$installwim" "$language\$($packages[$i])") {
								Write-Host "`t`t`t`t`t - $($packages[$i])" -ForegroundColor Green
							} else {
								Write-Host "`t`t`t`t`t - $($packages[$i])" -ForegroundColor Red
								break
							}
						}
					}
				} else {
					Write-Host "Skipping" -ForegroundColor Magenta
				}

				Write-Host -ForegroundColor White "`t`t`tWriting overlay... " -NoNewline
				try {
					Copy-Item "$pwd\sources\$sourcefolder\overlays\windows\base\*" -Destination "${installwim}_mount\" -Recurse -Force

					if (Test-Path -Path "$pwd\sources\$sourcefolder\overlays\windows\$($installwim.BaseName)\$imageIndex") {
						Copy-Item "$pwd\sources\$sourcefolder\overlays\windows\$($installwim.BaseName)\$imageIndex\*" -Destination "${installwim}_mount\" -Recurse -Force
						Write-Host "OK (Custom)" -ForegroundColor Green
					} else {
						Write-Host "OK (Base)" -ForegroundColor Green
					}
				} catch {
					Write-Host "Failed" -ForegroundColor Red
				}

				Write-Host -ForegroundColor White "`t`t`tOptimizing image... " -NoNewline
				if (OptimizeWIM $installwim) {
					Write-Host "OK" -ForegroundColor Green
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}

				Write-Host -ForegroundColor White "`t`t`tCommiting changes... " -NoNewline
				if (FinishWIM $installwim) {
					Write-Host "OK" -ForegroundColor Green
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}

				Write-Host "`t`t`tExporting '$imageName'..." -NoNewline -ForegroundColor White
				if (ExportWIMIndex $installwim ($destinationfolder + "\$fileName") $imageIndex) {
					Write-Host "OK" -ForegroundColor Green
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}

				Log "INFO" "Writing entry to images.ini..."
				Write-Host "`t`t`tWriting entry to images.ini... " -ForegroundColor White -NoNewLine
				$INITemplate = "$imageName=$fileName"
				Add-Content "$destinationfolder\images.ini" $INITemplate
				Write-Host "OK" -ForegroundColor Green
			} else {
				Log "ERROR" "Failed to install updates"
				Write-Host "Failed" -ForegroundColor Red
			}
		}
	}
}