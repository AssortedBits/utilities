set unixdir=%~dp0
set unixexe=%unixdir%lspw
bash -c -l "$(wslpath -u '%unixexe%') vi"
pause
