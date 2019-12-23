
function ExtractXMLFromWIM($wimfile) {
    $rawWIM = [System.IO.File]::OpenRead($wimfile)

    $rawWIM.seek(0x50,0)
    $bytes = New-Object -TypeName Byte[] -ArgumentList 8
    $rawWIM.read($bytes,0,$bytes.Length)
    $startOfXML = [System.BitConverter]::toInt64($bytes, 0)
    $rawWIM.read($bytes,0,$bytes.Length)
    $endOfXML = $startOfXML + [System.BitConverter]::toInt64($bytes, 0)

    $xmlSize = $endOfXML - $startOfXML - 2
    $position = $rawWIM.seek($startOfXML + 2, 0)
    $bytes = New-Object -TypeName Byte[] -ArgumentList $xmlSize
    $rawWIM.read($bytes,0,$bytes.Length)

    $rawWIM.Close()
    [xml]$result = [System.Text.Encoding]::Unicode.getString($bytes, 0, $bytes.Length)
    return $result
}
