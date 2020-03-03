function InstallChoco() {
    Log "INFO" "Installing choco"

    try {
        Log "INFO" "Checking if choco is already installed..."
        Get-Command "choco" -ErrorAction Stop | Out-Null
        Log "INFO" "Choco is already installed  skipping installation."
    } catch {
        Log "INFO" "Choco not installed  triggering remote installation script..."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        Log "INFO" "Done installing Choco"
    }
}