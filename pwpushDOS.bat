set unixdir=%~dp0
set unixexe=%unixdir%pwpush
bash -c -l "$(wslpath -u '%unixexe%')"
pause
