Function Log {
    Param($type, $message)
    $timestamp = '[{0:MM/dd/yy} {0:HH:mm:ss}]' -f (Get-Date)
    Add-Content "output.log" "$type $timestamp $message"
}