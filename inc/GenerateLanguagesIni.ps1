function GenerateLanguagesIni($wimFile) {
    Log "INFO" "Generating INI files"
    dism /image:"${wimFile}_mount" /distribution:"${wimFile}_mount" /Gen-LangINI  2>&1> $null
    Copy-Item "${wimFile}_mount/sources/lang.ini" "$pwd/iso/sources/lang.ini"

    if ($? -ne 0) {
        Log "INFO" "Successfully generated Languages INI"
        return $true;
    }

    Log "ERROR" "Failed to generate Languages INI"
    return $false;
}