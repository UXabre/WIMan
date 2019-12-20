@echo off
call ..\_config.cmd
echo Loading WinPE...
wpeinit

call peSetup.cmd
