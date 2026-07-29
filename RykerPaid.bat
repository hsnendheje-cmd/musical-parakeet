@echo off
setlocal enabledelayedexpansion
cls
chcp 65001 >nul 2>&1
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

set "YELLOW=%ESC%[38;5;226m"
set "LYELLOW=%ESC%[38;5;229m"
set "DYELLOW=%ESC%[38;5;136m"
set "PURPLE=%ESC%[38;5;129m"
set "LPURPLE=%ESC%[38;5;171m"
set "DPURPLE=%ESC%[38;5;54m"
set "WHITE=%ESC%[97m"
set "GRAY=%ESC%[90m"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"

set "G1=%ESC%[38;5;171m"
set "G2=%ESC%[38;5;141m"
set "G3=%ESC%[38;5;129m"
set "G4=%ESC%[38;5;93m"
set "G5=%ESC%[38;5;57m"
set "G6=%ESC%[38;5;54m"

if not defined RykerPaid_BASE_DIR (
    set "RykerPaid_BASE_DIR=%~dp0"
)
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$out=$env:MENU_RESULT;$rpc=$env:USE_RPC -eq '1';$items=@();$ids=@();$items+='EAC Bypass';$ids+='eac';$items+='RykerPaid Menu';$ids+='menu';$items+='Recheck Environment';$ids+='recheck';$art=@('  ██████╗  ██╗   ██╗ ██╗  ██╗ ███████╗ ██████╗ ','  ██╔══██╗ ╚██╗ ██╔╝ ██║ ██╔╝ ██╔════╝ ██╔══██╗','  ██████╔╝  ╚████╔╝  █████╔╝  █████╗   ██████╔╝','  ██╔══██╗   ╚██╔╝   ██╔═██╗  ██╔══╝   ██╔══██╗','  ██║  ██║    ██║    ██║  ██╗ ███████╗ ██║  ██║','  ╚═╝  ╚═╝    ╚═╝    ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝');$gc=@(171,141,129,93,57,54);$e=[char]27;$selected=0;try{[Console]::CursorVisible=$false;while($true){[Console]::Clear();for($li=0;$li -lt $art.Count;$li++){[Console]::WriteLine($e+'[38;5;'+$gc[$li]+'m'+$art[$li]+$e+'[0m')};[Console]::ForegroundColor='DarkGray';[Console]::WriteLine('   ----------------------------------------------------');[Console]::ResetColor();[Console]::ForegroundColor='Magenta';[Console]::WriteLine('              RYKER Frida Engine Controller');[Console]::ResetColor();[Console]::ForegroundColor='DarkGray';[Console]::WriteLine('                   discord.gg/bGkrWETD6');[Console]::WriteLine('   ----------------------------------------------------');[Console]::ResetColor();[Console]::WriteLine('');[Console]::WriteLine('    Up/Down or W/S = Navigate   Enter = Launch   D = Toggle Discord RPC');[Console]::WriteLine('    Discord RPC Status: '+$(if($rpc){'Enabled'}else{'Disabled'}));[Console]::WriteLine('');for($i=0;$i -lt $items.Count;$i++){if($i -eq $selected){[Console]::ForegroundColor='White';[Console]::BackgroundColor='DarkMagenta';[Console]::WriteLine(' > '+$items[$i]+' ');[Console]::ResetColor()}else{[Console]::ForegroundColor='DarkGray';[Console]::WriteLine('   '+$items[$i]);[Console]::ResetColor()}};$key=[Console]::ReadKey($true);if($key.Key -eq 'UpArrow' -or ($key.Key -eq 'W' -and -not $key.Modifiers)){$selected=($selected+$items.Count-1)%%$items.Count}elseif($key.Key -eq 'DownArrow' -or ($key.Key -eq 'S' -and -not $key.Modifiers)){$selected=($selected+1)%%$items.Count}elseif($key.Key -eq 'Enter'){Set-Content -LiteralPath $out -Value $ids[$selected];break}elseif($key.Key -eq 'D' -and -not $key.Modifiers){Set-Content -LiteralPath $out -Value 'toggle_rpc';break}}}finally{[Console]::ResetColor();[Console]::CursorVisible=$true}"
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
) else (
    call :save_rpc_pref
)
exit /b 0

:save_rpc_pref
> "%SETTINGS_FILE%" echo USE_RPC=%USE_RPC%
exit /b 0

:toggle_rpc
if "%USE_RPC%"=="1" (
    set "USE_RPC=0"
    call :save_rpc_pref
    call :banner
    echo %LPURPLE%   [+]%RESET% Discord RPC is now off. NPM checks will be skipped.
) else (
    set "USE_RPC=1"
    call :save_rpc_pref
    call :banner
    echo %LPURPLE%   [+]%RESET% Discord RPC is now on.
)
echo.
echo %GRAY%   Returning to main menu...%RESET%
ping -n 2 127.0.0.1 >nul
goto :main_menu

:launch_bypass
call :banner
if not exist "%RykerPaid_BASE_DIR%EACBypass.py" (
    echo %LPURPLE%   [x]%RESET% Missing EACBypass.py beside run.bat.
    pause
    goto :main_menu
)
echo.
echo %LPURPLE%   [+]%RESET% Launching EAC Bypass script in a separate window...
set "BYPASS_WORKER=%TEMP%\RykerPaid_bypass_%RANDOM%%RANDOM%.bat"
(
    echo @echo off
    echo set "RykerPaid_BASE_DIR=%RykerPaid_BASE_DIR%"
    echo call "%~f0" __bypass_worker
) > "%BYPASS_WORKER%"
start "EAC Bypass" "%ComSpec%" /k call "%BYPASS_WORKER%"
echo.
echo %GRAY%   Returning to menu...%RESET%
ping -n 2 127.0.0.1 >nul
goto :main_menu

:bypass_worker
title EAC Bypass
call :banner
if not exist "%RykerPaid_BASE_DIR%EACBypass.py" (
    echo %LPURPLE%   [x]%RESET% Missing EACBypass.py beside run.bat.
    pause
    exit /b 1
)
call :ensure_python
if errorlevel 1 (
    pause
    exit /b 1
)
echo %LPURPLE%%BOLD%   Executing EACBypass.py%RESET%
echo.
python "%RykerPaid_BASE_DIR%EACBypass.py"
echo.
echo %PURPLE%   Process finished.%RESET%
echo %GRAY%   This terminal window will remain open for debug logs.
cmd /k
exit /b 0

:run_RykerPaid_menu
call :banner
call :run_basic_checks
if errorlevel 1 goto :main_menu
call :maybe_start_rpc

echo.
echo %GRAY%   ----------------------------------------------------%RESET%
echo %LPURPLE%%BOLD%   Launching RYKER Menu%RESET%
echo %GRAY%   ----------------------------------------------------%RESET%
echo.
echo %GRAY%   Target : %WHITE%EACLauncher.exe%RESET%
echo %GRAY%   Engine : %WHITE%ac_bridge.js%RESET%
echo %GRAY%   Script : %WHITE%RykerPaid.js%RESET%
echo.
echo %WHITE%   Waiting for initialization, press any key to start RYKER...%RESET%
pause >nul

Frida -l ac_bridge.js -l RykerPaid.js "EACLauncher.exe"
pause

if errorlevel 1 (
    echo.
    echo %LPURPLE%   [x]%RESET% Frida exited with an error. Verify that frida-tools is updated and 'RykerPaid.js' exists in your folder.
)

echo.
echo %PURPLE%   Session terminated.%RESET%
pause
goto :main_menu

:run_recheck
call :banner
call :_patchLauncher
call :run_basic_checks
if errorlevel 1 goto :main_menu
if "%USE_RPC%"=="1" (
    call :ensure_node_rpc
    if errorlevel 1 goto :main_menu
) else (
    echo.
    echo %LPURPLE%   [+]%RESET% Discord RPC is disabled. Skipping dependency checks.
)
echo.
echo %LPURPLE%   [+]%RESET% Verification finished.
echo %GRAY%   Returning to menu...%RESET%
ping -n 2 127.0.0.1 >nul
goto :main_menu

:run_basic_checks
call :ensure_python
if errorlevel 1 exit /b 1
call :ensure_frida
if errorlevel 1 exit /b 1
exit /b 0

:ensure_python
call :spin_msg "Checking Python installation..."
python --version >nul 2>&1
if errorlevel 1 (
    echo %PURPLE%   [!]%RESET% Python not found. Installing via winget...
    winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo %LPURPLE%   [!]%RESET% Automated installation failed. Install Python 3 manually.
        pause
        exit /b 1
    )
    set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
    echo %LPURPLE%   [+]%RESET% Python installation completed.
) else (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo %LPURPLE%   [+]%RESET% %%v detected.
)
exit /b 0

:ensure_frida
echo.
call :spin_msg "Checking Frida setup..."
pip show frida-tools >nul 2>&1
if errorlevel 1 (
    echo %PURPLE%   [!]%RESET% frida-tools missing. Installing...
    pip install frida-tools --quiet
    if errorlevel 1 (
        pip install frida-tools --user --quiet
        if errorlevel 1 (
            echo %LPURPLE%   [x]%RESET% Failed to install frida-tools. Please run 'pip install frida-tools' manually.
            pause
            exit /b 1
        )
    )
    echo %LPURPLE%   [+]%RESET% frida-tools successfully configured.
) else (
    for /f "tokens=*" %%v in ('pip show frida-tools 2^>^&1 ^| findstr "Version"') do echo %LPURPLE%   [+]%RESET% frida-tools %%v found.
)
exit /b 0

:maybe_start_rpc
if not "%USE_RPC%"=="1" (
    echo.
    echo %LPURPLE%   [+]%RESET% Discord RPC active indicator skipped.
    exit /b 0
)
if not exist "%RykerPaid_BASE_DIR%rpcdiscord.ts" (
    echo.
    echo %LPURPLE%   [+]%RESET% rpcdiscord.ts not detected. Skipped.
    exit /b 0
)
call :ensure_node_rpc
if errorlevel 1 exit /b 1
echo.
call :spin_msg "Starting Discord RPC..."
start "Discord RPC" cmd /k "cd /d ""%RykerPaid_BASE_DIR%"" && set TS_NODE_COMPILER_OPTIONS={""module"":""CommonJS"",""moduleResolution"":""node""}&& npx ts-node --transpile-only rpcdiscord.ts"
echo %LPURPLE%   [+]%RESET% RPC integration operational.
exit /b 0

:ensure_node_rpc
echo.
call :spin_msg "Checking Node.js..."
node --version >nul 2>&1
if errorlevel 1 (
    echo %PURPLE%   [!]%RESET% Node.js missing. Installing via winget...
    winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo %LPURPLE%   [!]%RESET% winget failure. Please install Node.js manually.
        pause
        exit /b 1
    )
    set "PATH=%ProgramFiles%\nodejs;%PATH%"
    echo %LPURPLE%   [+]%RESET% Node.js successfully installed.
) else (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do echo %LPURPLE%   [+]%RESET% Node %%v found.
)

echo.
call :spin_msg "Configuring packages..."
if not exist "%RykerPaid_BASE_DIR%node_modules\discord-rpc" (
    echo %PURPLE%   [!]%RESET% Missing node packages. Resolving dependencies...
    pushd "%RykerPaid_BASE_DIR%"
    call npm install discord-rpc ts-node typescript @types/node --no-fund --no-audit --loglevel=error
    popd
    if errorlevel 1 (
        echo %LPURPLE%   [x]%RESET% Package configuration failed.
        pause
        exit /b 1
    )
    echo %LPURPLE%   [+]%RESET% Dependencies successfully updated.
) else (
    echo %LPURPLE%   [+]%RESET% Local packages loaded.
)
exit /b 0

:spin_msg
set "_smsg=%~1"
set "_idx=0"
for /l %%x in (1,1,12) do (
    set /a "_idx=_idx+1"
    set /a "_r=_idx%%4"
    if !_r!==0 set "_c=/"
    if !_r!==1 set "_c=-"
    if !_r!==2 set "_c=^\"
    if !_r!==3 set "_c=^|"
    <nul set /p "=%ESC%[2K%PURPLE%   [!_c!]%RESET% %_smsg%%ESC%[1G"
    ping -n 1 -w 200 127.0.0.1 >nul 2>&1
)
<nul set /p "=%ESC%[2K"
exit /b 0

:banner
cls
echo %BOLD%%G1%   ██████╗  ██╗   ██╗ ██╗  ██╗ ███████╗ ██████╗%RESET%
echo %BOLD%%G2%   ██╔══██╗ ╚██╗ ██╔╝ ██║ ██╔╝ ██╔════╝ ██╔══██╗%RESET%
echo %BOLD%%G3%   ██████╔╝  ╚████╔╝  █████╔╝  █████╗   ██████╔╝%RESET%
echo %BOLD%%G4%   ██╔══██╗   ╚██╔╝   ██╔═██╗  ██╔══╝   ██╔══██╗%RESET%
echo %BOLD%%G5%   ██║  ██║    ██║    ██║  ██╗ ███████╗ ██║  ██║%RESET%
echo %BOLD%%G6%   ╚═╝  ╚═╝    ╚═╝    ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝%RESET%
echo.
exit /b 0

:_patchLauncher
powershell -NoProfile -ExecutionPolicy Bypass -Command "$steam=$null; foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')){if(Test-Path $key){$props=Get-ItemProperty $key -ErrorAction SilentlyContinue; $steam=if($props.SteamPath){$props.SteamPath}else{$props.InstallPath}; if($steam){break}}}; if(-not $steam){exit}; $libraries=@($steam); $vdf=Join-Path $steam 'steamapps\libraryfolders.vdf'; if(Test-Path $vdf){$libraries+=Select-String -LiteralPath $vdf -Pattern '^\s*\x22path\x22\s+\x22([^\x22]+)\x22' | ForEach-Object {$_.Matches[0].Groups[1].Value -replace '\\\\','\'}}; foreach($library in ($libraries | Select-Object -Unique)){$common=Join-Path $library 'steamapps\common'; if(-not(Test-Path $common)){continue}; Get-ChildItem -LiteralPath $common -Directory -ErrorAction SilentlyContinue | Where-Object {$_.Name -like 'Animal Company*'} | ForEach-Object {$ini=Join-Path $_.FullName 'AnimalCompanyLauncher.ini'; @('ApplicationPath=EACLauncher.exe','WorkingDirectory=','ClientDirectory=','WaitForExit=0','NoOperation=0') | Set-Content -LiteralPath $ini -Encoding ASCII}}"
goto :eof
