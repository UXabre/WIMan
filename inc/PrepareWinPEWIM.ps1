function PrepareWinPEWIM($iso, $outputfolder) {
    $architecture = ([System.IO.FileInfo]$iso).Directory.Parent.Name
    $sourcefolder = $architecture + "\" + ([System.IO.FileInfo]$iso).Directory.Name
    $destinationfolder = $outputfolder + $sourcefolder + '\sources\'
    $bootwim = $tempfolder + $sourcefolder + '\sources\boot.wim'

    New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null
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

        New-Item -Force -ItemType directory -Path $destinationfolder | Out-Null

        if (Test-Path ($destinationfolder + "\" + 'boot.wim') -PathType Leaf) {
            Write-Host "`t`tDeleting older boot.wim... " -NoNewline -ForegroundColor White
            Remove-Item ($destinationfolder + "\" + 'boot.wim') -Force | Out-Null

            if ($? -ne 0) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }
        }

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