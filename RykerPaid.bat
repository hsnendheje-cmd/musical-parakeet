@echo off
setlocal enabledelayedexpansion
cls
chcp 65001 >nul 2>&1
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
mode con: cols=72 lines=40 >nul 2>&1

set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "DIM=%ESC%[2m"

set "C0=%ESC%[38;5;129m"
set "C1=%ESC%[38;5;92m"
set "C2=%ESC%[38;5;91m"
set "C3=%ESC%[38;5;55m"
set "C4=%ESC%[38;5;54m"
set "C5=%ESC%[38;5;53m"

set "PURPLE=%ESC%[38;5;135m"
set "LPURPLE=%ESC%[38;5;177m"
set "VPURPLE=%ESC%[38;5;183m"
set "DPURPLE=%ESC%[38;5;54m"
set "WHITE=%ESC%[97m"
set "GRAY=%ESC%[38;5;242m"
set "DGRAY=%ESC%[38;5;238m"
set "GREEN=%ESC%[38;5;84m"
set "RED=%ESC%[38;5;203m"
set "AMBER=%ESC%[38;5;221m"
set "CYAN=%ESC%[38;5;123m"

if not defined RykerPaid_BASE_DIR set "RykerPaid_BASE_DIR=%~dp0"
if not "%RykerPaid_BASE_DIR:~-1%"=="\" set "RykerPaid_BASE_DIR=%RykerPaid_BASE_DIR%\"
set "SETTINGS_FILE=%RykerPaid_BASE_DIR%Ryker_Prefs.ini"

if /i "%~1"=="__bypass_worker" goto :bypass_worker
if /i "%~1"=="__menu" goto :start_main
call :_patchLauncher

:start_main
call :load_rpc_pref

:main_menu
call :pick_menu
if /i "%MENU_PICK%"=="toggle_rpc" goto :toggle_rpc
if /i "%MENU_PICK%"=="eac" goto :launch_bypass
if /i "%MENU_PICK%"=="menu" goto :run_RykerPaid_menu
if /i "%MENU_PICK%"=="recheck" goto :run_recheck
goto :run_RykerPaid_menu

:pick_menu
set "MENU_PICK="
set "MENU_RESULT=%TEMP%\RykerPaid_menu_%RANDOM%%RANDOM%.txt"
if exist "%MENU_RESULT%" del /f /q "%MENU_RESULT%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$out=$env:MENU_RESULT;$rpc=$env:USE_RPC -eq '1';$items=@('EAC Bypass','RykerPaid Menu','Recheck Environment');$ids=@('eac','menu','recheck');$art=@(' ██████╗ ██╗   ██╗██╗  ██╗███████╗██████╗ ',' ██╔══██╗╚██╗ ██╔╝██║ ██╔╝██╔════╝██╔══██╗',' ██████╔╝ ╚████╔╝ █████╔╝ █████╗  ██████╔╝',' ██╔══██╗  ╚██╔╝  ██╔═██╗ ██╔══╝  ██╔══██╗',' ██║  ██║   ██║   ██║  ██╗███████╗██║  ██║',' ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝');$gc=@(129,92,91,55,54,53);$e=[char]27;$W=68;$sel=0;function Grad([string]$line){$o='';$len=$line.Length;for($k=0;$k -lt $len;$k++){$t=$k/[math]::Max($len-1,1);$r=[math]::Floor(180-(110*$t));$g=[math]::Floor(60-(50*$t));$b=[math]::Floor(255-(60*$t));$o+=$e+'[38;2;'+$r+';'+$g+';'+$b+'m'+$line[$k]};return $o+$e+'[0m'};function Bar([int]$w){return('─'*$w)};try{[Console]::CursorVisible=$false;while($true){[Console]::Clear();[Console]::WriteLine('');foreach($i in 0..($art.Count-1)){$pad=[math]::Floor(($W-$art[$i].Length)/2);[Console]::WriteLine((' '*$pad)+(Grad $art[$i]))};[Console]::WriteLine('');$top=' '+[char]0x256D+(Bar ($W-4))+[char]0x256E;$bot=' '+[char]0x2570+(Bar ($W-4))+[char]0x256F;[Console]::WriteLine($e+'[38;5;54m'+$top+$e+'[0m');$brand='R Y K E R   P A I D';$bp=[math]::Floor(($W-4-$brand.Length)/2);$line=' '+[char]0x2502+(' '*$bp)+$brand+(' '*($W-4-$bp-$brand.Length))+[char]0x2502;[Console]::Write($e+'[38;5;54m'+' '+[char]0x2502+$e+'[0m');[Console]::Write($e+'[1m'+$e+'[38;5;183m'+(' '*$bp)+$brand+$e+'[0m');[Console]::Write((' '*($W-4-$bp-$brand.Length)));[Console]::WriteLine($e+'[38;5;54m'+[char]0x2502+$e+'[0m');$dc='discord.gg/ryker';$dp=[math]::Floor(($W-4-$dc.Length)/2);[Console]::Write($e+'[38;5;54m'+' '+[char]0x2502+$e+'[0m');[Console]::Write($e+'[38;5;242m'+(' '*$dp)+$dc+$e+'[0m');[Console]::Write((' '*($W-4-$dp-$dc.Length)));[Console]::WriteLine($e+'[38;5;54m'+[char]0x2502+$e+'[0m');[Console]::WriteLine($e+'[38;5;54m'+$bot+$e+'[0m');[Console]::WriteLine('');$rpcTxt=if($rpc){$e+'[38;5;84m●'+$e+'[0m'+$e+'[38;5;242m RPC Active'}else{$e+'[38;5;203m●'+$e+'[0m'+$e+'[38;5;242m RPC Off'};[Console]::WriteLine('   '+$rpcTxt+$e+'[0m');[Console]::ForegroundColor='DarkGray';[Console]::WriteLine('   '+[char]0x2191+[char]0x2193+' Navigate    Enter Select    D Toggle RPC');[Console]::ResetColor();[Console]::WriteLine('');for($i=0;$i -lt $items.Count;$i++){$num='0'+($i+1);if($i -eq $sel){[Console]::Write($e+'[48;5;54m'+$e+'[38;5;183m'+'  '+[char]0x25B8+' '+$e+'[0m');[Console]::Write($e+'[48;5;54m'+$e+'[38;5;242m'+$num+'  '+$e+'[0m');[Console]::Write($e+'[48;5;54m'+$e+'[1m'+$e+'[97m'+$items[$i].PadRight($W-10)+$e+'[0m');[Console]::WriteLine('')}else{[Console]::Write($e+'[38;5;238m'+'    '+$e+'[0m');[Console]::Write($e+'[38;5;240m'+$num+'  '+$e+'[0m');[Console]::WriteLine($e+'[38;5;245m'+$items[$i]+$e+'[0m')}};[Console]::WriteLine('');$key=[Console]::ReadKey($true);if($key.Key -eq 'UpArrow' -or($key.Key -eq 'W')){$sel=($sel+$items.Count-1)%%$items.Count}elseif($key.Key -eq 'DownArrow' -or($key.Key -eq 'S')){$sel=($sel+1)%%$items.Count}elseif($key.Key -eq 'Enter'){Set-Content -LiteralPath $out -Value $ids[$sel];break}elseif($key.Key -eq 'D'){Set-Content -LiteralPath $out -Value 'toggle_rpc';break}}}finally{[Console]::ResetColor();[Console]::CursorVisible=$true}"
if exist "%MENU_RESULT%" (
    set /p "MENU_PICK="<"%MENU_RESULT%"
    del /f /q "%MENU_RESULT%" >nul 2>&1
)
if not defined MENU_PICK set "MENU_PICK=menu"
exit /b 0

:load_rpc_pref
set "USE_RPC=0"
if exist "%SETTINGS_FILE%" (
    findstr /i /c:"USE_RPC=1" "%SETTINGS_FILE%" >nul 2>&1
    if !errorlevel!==0 set "USE_RPC=1"
) else ( call :save_rpc_pref )
exit /b 0

:save_rpc_pref
> "%SETTINGS_FILE%" echo USE_RPC=%USE_RPC%
exit /b 0

:toggle_rpc
if "%USE_RPC%"=="1" (
    set "USE_RPC=0" & call :save_rpc_pref
    call :banner
    call :panel_top "SETTINGS"
    call :prow "%RED%●%RESET%  Discord RPC disabled  %GRAY%npm checks skipped%RESET%"
    call :panel_bottom
) else (
    set "USE_RPC=1" & call :save_rpc_pref
    call :banner
    call :panel_top "SETTINGS"
    call :prow "%GREEN%●%RESET%  Discord RPC enabled"
    call :panel_bottom
)
call :footer_wait
goto :main_menu

:launch_bypass
call :banner
call :panel_top "EAC BYPASS"
if not exist "%RykerPaid_BASE_DIR%EACBypass.py" (
    call :prow "%RED%✕  EACBypass.py not found beside run.bat%RESET%"
    call :panel_bottom
    pause & goto :main_menu
)
call :prow "%GREEN%✓%RESET%  Launching bypass in a new window"
call :panel_bottom
set "BYPASS_WORKER=%TEMP%\RykerPaid_bypass_%RANDOM%%RANDOM%.bat"
(
    echo @echo off
    echo set "RykerPaid_BASE_DIR=%RykerPaid_BASE_DIR%"
    echo call "%~f0" __bypass_worker
) > "%BYPASS_WORKER%"
start "EAC Bypass" "%ComSpec%" /k call "%BYPASS_WORKER%"
call :footer_wait
goto :main_menu

:bypass_worker
title EAC Bypass - Ryker
call :banner
call :panel_top "EAC BYPASS"
if not exist "%RykerPaid_BASE_DIR%EACBypass.py" (
    call :prow "%RED%✕  EACBypass.py not found%RESET%"
    call :panel_bottom
    pause & exit /b 1
)
call :ensure_python
if errorlevel 1 ( pause & exit /b 1 )
call :prow "%CYAN%▸%RESET%  Executing  %WHITE%EACBypass.py%RESET%"
call :panel_bottom
echo.
python "%RykerPaid_BASE_DIR%EACBypass.py"
echo.
echo   %DPURPLE%▚▚▚%RESET%  %GRAY%Session finished. Window stays open for logs.%RESET%
cmd /k
exit /b 0

:run_RykerPaid_menu
call :banner
call :panel_top "ENVIRONMENT"
call :run_basic_checks
if errorlevel 1 ( call :panel_bottom & goto :main_menu )
call :maybe_start_rpc
call :panel_bottom
echo.
call :panel_top "LAUNCH TARGET"
call :prow "%GRAY%Target%RESET%   %WHITE%EACLauncher.exe%RESET%"
call :prow "%GRAY%Engine%RESET%   %WHITE%ac_bridge.js%RESET%"
call :prow "%GRAY%Script%RESET%   %WHITE%RykerPaid.js%RESET%"
call :panel_bottom
echo.
echo   %VPURPLE%▸%RESET%  %WHITE%Press any key to inject and start RYKER...%RESET%
pause >nul
echo.
call :spin_msg "Attaching Frida to EACLauncher.exe"
Frida -l ac_bridge.js -l RykerPaid.js "EACLauncher.exe"
if errorlevel 1 (
    echo.
    echo   %RED%✕%RESET%  Frida exited with an error. Update frida-tools and verify RykerPaid.js exists.
)
echo.
echo   %DPURPLE%▚▚▚%RESET%  %GRAY%Session terminated.%RESET%
pause
goto :main_menu

:run_recheck
call :banner
call :_patchLauncher
call :panel_top "ENVIRONMENT"
call :run_basic_checks
if errorlevel 1 ( call :panel_bottom & goto :main_menu )
if "%USE_RPC%"=="1" (
    call :ensure_node_rpc
    if errorlevel 1 ( call :panel_bottom & goto :main_menu )
) else (
    call :prow "%GRAY%◌  RPC disabled - node checks skipped%RESET%"
)
call :prow "%GREEN%✓  All checks passed%RESET%"
call :panel_bottom
call :footer_wait
goto :main_menu

:run_basic_checks
call :ensure_python
if errorlevel 1 exit /b 1
call :ensure_frida
if errorlevel 1 exit /b 1
exit /b 0

:ensure_python
call :spin_msg "Checking Python runtime"
python --version >nul 2>&1
if errorlevel 1 (
    call :prow "%AMBER%!%RESET%  Python missing - installing via winget"
    winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        call :prow "%RED%✕  Install failed - add Python 3 manually%RESET%"
        pause & exit /b 1
    )
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
    call :prow "%GREEN%✓%RESET%  Python installed"
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do call :prow "%GREEN%✓%RESET%  %%v"
)
exit /b 0

:ensure_frida
call :spin_msg "Checking Frida toolkit"
pip show frida-tools >nul 2>&1
if errorlevel 1 (
    call :prow "%AMBER%!%RESET%  frida-tools missing - installing"
    pip install frida-tools --quiet
    if errorlevel 1 (
        pip install frida-tools --user --quiet
        if errorlevel 1 (
            call :prow "%RED%✕  Install failed - run pip install frida-tools%RESET%"
            pause & exit /b 1
        )
    )
    call :prow "%GREEN%✓%RESET%  frida-tools installed"
) else (
    for /f "tokens=*" %%v in ('pip show frida-tools 2^>^&1 ^| findstr "Version"') do call :prow "%GREEN%✓%RESET%  frida-tools %%v"
)
exit /b 0

:maybe_start_rpc
if not "%USE_RPC%"=="1" (
    call :prow "%GRAY%◌  RPC disabled%RESET%"
    exit /b 0
)
if not exist "%RykerPaid_BASE_DIR%rpcdiscord.ts" (
    call :prow "%GRAY%◌  rpcdiscord.ts not found - skipped%RESET%"
    exit /b 0
)
call :ensure_node_rpc
if errorlevel 1 exit /b 1
call :spin_msg "Starting Discord RPC"
start "Discord RPC" cmd /k "cd /d ""%RykerPaid_BASE_DIR%"" && set TS_NODE_COMPILER_OPTIONS={""module"":""CommonJS"",""moduleResolution"":""node""}&& npx ts-node --transpile-only rpcdiscord.ts"
call :prow "%GREEN%✓%RESET%  Discord RPC running"
exit /b 0

:ensure_node_rpc
call :spin_msg "Checking Node.js"
node --version >nul 2>&1
if errorlevel 1 (
    call :prow "%AMBER%!%RESET%  Node missing - installing via winget"
    winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        call :prow "%RED%✕  Install failed - add Node.js manually%RESET%"
        pause & exit /b 1
    )
    set "PATH=%ProgramFiles%\nodejs;%PATH%"
    call :prow "%GREEN%✓%RESET%  Node.js installed"
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do call :prow "%GREEN%✓%RESET%  Node %%v"
)
call :spin_msg "Resolving npm packages"
if not exist "%RykerPaid_BASE_DIR%node_modules\discord-rpc" (
    call :prow "%AMBER%!%RESET%  Installing dependencies"
    pushd "%RykerPaid_BASE_DIR%"
    call npm install discord-rpc ts-node typescript @types/node --no-fund --no-audit --loglevel=error
    popd
    if errorlevel 1 (
        call :prow "%RED%✕  npm install failed%RESET%"
        pause & exit /b 1
    )
    call :prow "%GREEN%✓%RESET%  Dependencies installed"
) else (
    call :prow "%GREEN%✓%RESET%  Packages ready"
)
exit /b 0

:spin_msg
set "_smsg=%~1"
set "_idx=0"
for /l %%x in (1,1,14) do (
    set /a "_idx=_idx+1"
    set /a "_r=_idx%%8"
    if !_r!==0 set "_c=⠋"
    if !_r!==1 set "_c=⠙"
    if !_r!==2 set "_c=⠹"
    if !_r!==3 set "_c=⠸"
    if !_r!==4 set "_c=⠼"
    if !_r!==5 set "_c=⠴"
    if !_r!==6 set "_c=⠦"
    if !_r!==7 set "_c=⠧"
    <nul set /p "=%ESC%[2K %DGRAY%│%RESET%  %LPURPLE%!_c!%RESET%  %GRAY%%_smsg%...%RESET%%ESC%[1G"
    ping -n 1 -w 90 127.0.0.1 >nul 2>&1
)
<nul set /p "=%ESC%[2K"
exit /b 0

:panel_top
set "_ttl=%~1"
echo  %DPURPLE%╭─%RESET% %BOLD%%LPURPLE%%_ttl%%RESET% %DPURPLE%────────────────────────────────────────%RESET%
echo  %DGRAY%│%RESET%
exit /b 0

:prow
echo  %DGRAY%│%RESET%  %~1
exit /b 0

:panel_bottom
echo  %DGRAY%│%RESET%
echo  %DPURPLE%╰──────────────────────────────────────────────────────%RESET%
exit /b 0

:footer_wait
echo.
echo   %DGRAY%returning to menu...%RESET%
ping -n 2 127.0.0.1 >nul
exit /b 0

:banner
cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "$e=[char]27;$art=@('','  ██████╗ ██╗   ██╗██╗  ██╗███████╗██████╗','  ██╔══██╗╚██╗ ██╔╝██║ ██╔╝██╔════╝██╔══██╗','  ██████╔╝ ╚████╔╝ █████╔╝ █████╗  ██████╔╝','  ██╔══██╗  ╚██╔╝  ██╔═██╗ ██╔══╝  ██╔══██╗','  ██║  ██║   ██║   ██║  ██╗███████╗██║  ██║','  ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝','');function grad($line){$out='';$len=$line.Length;for($i=0;$i -lt $len;$i++){$t=$i/[math]::Max($len-1,1);$r=[math]::Floor(180-(110*$t));$g=[math]::Floor(60-(50*$t));$b=[math]::Floor(255-(60*$t));$out+=$e+'[38;2;'+$r+';'+$g+';'+$b+'m'+$line[$i]};return $out+$e+'[0m'};foreach($l in $art){[Console]::WriteLine((grad $l))};$d='   ━━━━━━━━━━━━━━━━━━━ PAID ━━━━━━━━━━━━━━━━━━━';[Console]::WriteLine((grad $d));[Console]::WriteLine('')"
exit /b 0

:_patchLauncher
powershell -NoProfile -ExecutionPolicy Bypass -Command "$steam=$null; foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')){if(Test-Path $key){$props=Get-ItemProperty $key -ErrorAction SilentlyContinue; $steam=if($props.SteamPath){$props.SteamPath}else{$props.InstallPath}; if($steam){break}}}; if(-not $steam){exit}; $libraries=@($steam); $vdf=Join-Path $steam 'steamapps\libraryfolders.vdf'; if(Test-Path $vdf){$libraries+=Select-String -LiteralPath $vdf -Pattern '^\s*\x22path\x22\s+\x22([^\x22]+)\x22' | ForEach-Object {$_.Matches[0].Groups[1].Value -replace '\\\\','\'}}; foreach($library in ($libraries | Select-Object -Unique)){$common=Join-Path $library 'steamapps\common'; if(-not(Test-Path $common)){continue}; Get-ChildItem -LiteralPath $common -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -like 'Animal Company*'} | ForEach-Object {$ini=Join-Path $_.FullName 'AnimalCompanyLauncher.ini'; @('ApplicationPath=EACLauncher.exe','WorkingDirectory=','ClientDirectory=','WaitForExit=0','NoOperation=0') | Set-Content -LiteralPath $ini -Encoding ASCII}}"
goto :eof
