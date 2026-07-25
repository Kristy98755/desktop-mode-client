@echo off

setlocal enabledelayedexpansion
title Android Desktop Wizard v1.0

set "ROOT=%~dp0"
set "ESC="
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "C0=%ESC%[0m"
set "C1=%ESC%[97m"
set "C2=%ESC%[92m"
set "C3=%ESC%[93m"
set "C4=%ESC%[91m"
set "C5=%ESC%[96m"
set "CD=%ESC%[90m"

cls
echo.
chcp 65001 >nul 2>&1
type "%ROOT%modules\banner.txt"
chcp 866 >nul 2>&1
echo.

rem === PC INFO ===
echo %C3%  PC Hardware:%C0%
echo %CD%  ------------------------------------------------------------------------%C0%

set "PC_DATA=%TEMP%\adw_pc.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%modules\pc_info.ps1" > "%PC_DATA%" 2>nul

for /f "usebackq tokens=1,* delims==" %%a in ("%PC_DATA%") do (
    set "K=%%a"
    set "V=%%b"
    if "!K!"=="PC_CPU" echo %CD%    CPU:%C0%          !V!
    if "!K!"=="PC_CPU_CORES" set "CORES=!V!"
    if "!K!"=="PC_CPU_THREADS" echo %CD%    Cores/Threads:%C0% !CORES!/!V!
    if "!K!"=="PC_RAM_TOTAL" echo %CD%    RAM:%C0%          !V!
    if "!K!"=="PC_GPU1" echo %CD%    GPU1:%C0%         !V!
    if "!K!"=="PC_GPU2" echo %CD%    GPU2:%C0%         !V!
    if "!K!"=="PC_DISP1" echo %CD%    Display:%C0%       !V!
    if "!K!"=="PC_DISK1" echo %CD%    Disk1:%C0%         !V!
    if "!K!"=="PC_DISK2" echo %CD%    Disk2:%C0%         !V!
)
echo.

rem === DEVICE DETECTION ===
set "DEV_COUNT=0"
set "S="

for /f "skip=1 tokens=1,2" %%a in ('adb devices 2^>nul') do (
    if "%%b"=="device" (
        set /a "DEV_COUNT+=1"
        set "DEV_!DEV_COUNT!=%%a"
        for /f "delims=" %%m in ('adb -s %%a shell getprop ro.product.model 2^>nul') do set "DEV_M!DEV_COUNT!=%%m"
    )
)

if "!DEV_COUNT!"=="0" (
    echo %C4%  No Android devices found.%C0%
    echo %CD%  Connect a device with USB debugging enabled.%C0%
    pause
    goto :eof
)

if "!DEV_COUNT!"=="1" (
    set "S=!DEV_1!"
    set "PICK=1"
    goto :device_ok
)

rem === MULTI-DEVICE SELECTION ===
echo %C3%  Multiple devices found:%C0%
echo %CD%  ------------------------------------------------------------------------%C0%
set "DI=0"
:dev_list_loop
set /a "DI+=1"
if !DI! leq !DEV_COUNT! (
    echo %CD%    [!DI!] !DEV_M%DI%!  (!DEV_%DI%!^)
    goto :dev_list_loop
)
echo.

:dev_pick
set /p "PICK=  Select device [1-!DEV_COUNT!]: "
if not defined PICK goto :dev_pick
if !PICK! lss 1 goto :dev_pick
if !PICK! gtr !DEV_COUNT! goto :dev_pick

set "S=!DEV_%PICK%!"

rem Flash screen to confirm
echo.
echo %CD%    Flashing screen of !DEV_M%PICK%! ...%C0%
adb -s !S! shell input keyevent KEYCODE_WAKEUP >nul 2>&1
adb -s !S! shell settings put system screen_brightness 255 >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Milliseconds 125" 2>nul
adb -s !S! shell settings put system screen_brightness 0 >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Milliseconds 125" 2>nul
adb -s !S! shell settings put system screen_brightness 255 >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Milliseconds 125" 2>nul
adb -s !S! shell settings put system screen_brightness 0 >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Milliseconds 125" 2>nul
adb -s !S! shell settings put system screen_brightness 255 >nul 2>&1
echo.

set /p "CONFIRM=  Was that the right device? (Y/n): "
if /i "!CONFIRM!"=="n" goto :dev_pick

:device_ok
echo %C2%  Using: !DEV_M%PICK%!  (!S!)%C0%
echo.

rem === ANDROID INFO ===
echo %C3%  Android Device:%C0%
echo %CD%  ------------------------------------------------------------------------%C0%

set "AND_DATA=%TEMP%\adw_and.txt"

for /f "delims=" %%a in ('adb -s !S! shell getprop ro.product.model 2^>nul') do echo ANDROID_MODEL=%%a> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell getprop ro.product.brand 2^>nul') do echo ANDROID_BRAND=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell getprop ro.product.device 2^>nul') do echo ANDROID_DEVICE=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell getprop ro.build.version.release 2^>nul') do echo ANDROID_VER=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell getprop ro.build.version.sdk 2^>nul') do echo ANDROID_SDK=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell getprop ro.product.cpu.abi 2^>nul') do echo ANDROID_ABI=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell "cat /proc/cpuinfo | grep ^processor | wc -l" 2^>nul') do echo ANDROID_CORES=%%a>> "!AND_DATA!"
for /f "delims=" %%a in ('adb -s !S! shell wm size 2^>nul') do (
    echo %%a | findstr /c:"Physical size" >nul && (
        for /f "tokens=3" %%b in ("%%a") do echo ANDROID_DISP=%%b>> "!AND_DATA!"
    )
)
for /f "delims=" %%a in ('adb -s !S! shell wm density 2^>nul') do (
    echo %%a | findstr /c:"Physical density" >nul && (
        for /f "tokens=3" %%b in ("%%a") do echo ANDROID_DPI=%%b>> "!AND_DATA!"
    )
)
for /f "delims=" %%a in ('adb -s !S! shell "cat /proc/meminfo | head -1" 2^>nul') do (
    for /f "tokens=2" %%b in ("%%a") do (
        set /a "MB=%%b / 1024"
        echo ANDROID_RAM=!MB!MB>> "!AND_DATA!"
    )
)

rem Battery
for /f "delims=" %%a in ('adb -s !S! shell "dumpsys battery 2>/dev/null | grep ""  level:"" 2>/dev/null"') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do set "LVL=%%b"
)
for /f "delims=" %%a in ('adb -s !S! shell "dumpsys battery 2>/dev/null | grep scale"') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do set "SC=%%b"
)
if defined LVL if defined SC (
    set /a "BATT=!LVL! / !SC!"
    echo ANDROID_BATT=!BATT!%%>> "!AND_DATA!"
)
for /f "delims=" %%a in ('adb -s !S! shell "dumpsys battery 2>/dev/null | grep temperature"') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do (
        set "T=%%b"
        set "T=!T: =!"
        if defined T set /a "TC=!T! / 10"
        if defined TC echo ANDROID_TEMP=!TC!C>> "!AND_DATA!"
    )
)

rem Desktop mode - read, then auto-enable if off
for /f "delims=" %%a in ('adb -s !S! shell settings get global enable_freeform_support 2^>nul') do set "DM_FF=%%a"
for /f "delims=" %%a in ('adb -s !S! shell settings get global force_desktop_mode_on_external_displays 2^>nul') do set "DM_DE=%%a"
set "DM_ENABLED=0"
if "!DM_FF!"=="1" if "!DM_DE!"=="1" set "DM_ENABLED=1"
if "!DM_ENABLED!"=="0" (
    adb -s !S! shell settings put global enable_freeform_support 1 >nul 2>&1
    adb -s !S! shell settings put global force_desktop_mode_on_external_displays 1 >nul 2>&1
    adb -s !S! shell settings put global force_allow_on_external 1 >nul 2>&1
    echo ANDROID_DM=WAS_OFF^,NOW_ON>> "!AND_DATA!"
) else (
    echo ANDROID_DM=ON>> "!AND_DATA!"
)

rem Display info
for /f "usebackq tokens=1,* delims==" %%a in ("!AND_DATA!") do (
    set "K=%%a"
    set "V=%%b"
    if "!K!"=="ANDROID_MODEL" echo %CD%    Model:%C0%        !V!
    if "!K!"=="ANDROID_BRAND" echo %CD%    Brand:%C0%         !V!
    if "!K!"=="ANDROID_VER" echo %CD%    Android:%C0%       !V!
    if "!K!"=="ANDROID_SDK" echo %CD%    SDK:%C0%           !V!
    if "!K!"=="ANDROID_ABI" echo %CD%    ABI:%C0%           !V!
    if "!K!"=="ANDROID_CORES" echo %CD%    CPU Cores:%C0%     !V!
    if "!K!"=="ANDROID_DISP" echo %CD%    Resolution:%C0%    !V!
    if "!K!"=="ANDROID_DPI" echo %CD%    DPI:%C0%           !V!
    if "!K!"=="ANDROID_RAM" echo %CD%    RAM:%C0%           !V!
    if "!K!"=="ANDROID_TEMP" echo %CD%    Temp:%C0%          !V!
    if "!K!"=="ANDROID_BATT" echo %CD%    Battery:%C0%       !V!
    if "!K!"=="ANDROID_DM" (
        echo.
        echo %C3%    Desktop Mode:%C0%
        if "!V!"=="ON" (echo %CD%    Status:%C0%        %C2%already enabled%C0%)
        if "!V!"=="WAS_OFF,NOW_ON" (echo %CD%    Status:%C0%        %C2%was OFF, now enabled%C0%)
    )
)
echo.

rem === PROFILES ===
echo %C3%  Virtual Display Profiles:%C0%
echo %CD%  ------------------------------------------------------------------------%C0%

set "PC_W=1920"
set "PC_H=1080"
for /f "tokens=2 delims=x" %%a in ('findstr /c:"PRIMARY" "!PC_DATA!" 2^>nul') do (
    for /f "tokens=1" %%b in ("%%a") do set "PC_H=%%b"
)
for /f "tokens=2 delims==" %%a in ('findstr /c:"PRIMARY" "!PC_DATA!" 2^>nul') do (
    for /f "tokens=1 delims=x" %%b in ("%%a") do set "PC_W=%%b"
)

echo %CD%    Monitor: !PC_W!x!PC_H!
echo.

rem P1
set "R1=!PC_W!x!PC_H!"
set /a "PX1=!PC_W!*!PC_H!"
set /a "LD1=PX1/20736"
if !LD1! gtr 300 set "LD1=300"
set /a "MB1=PX1*12/1048576"
set /a "BT1=PX1*30/1000000"
set /a "SC1=(85*4+90*3+(100-LD1)*2+100)/10"
if !SC1! gtr 100 set "SC1=100"

rem P2
set "SKIP_P2=0"
if "!PC_W!x!PC_H!"=="1920x1080" set "SKIP_P2=1"
set /a "PX2=1920*1080"
set /a "LD2=PX2/20736"
set /a "MB2=PX2*12/1048576"
set /a "BT2=PX2*30/1000000"
set /a "SC2=(90*4+85*3+(100-LD2)*2+100)/10"
if !SC2! gtr 100 set "SC2=100"

rem P3
set /a "PX3=2560*1440"
set /a "LD3=PX3/20736"
if !LD3! gtr 300 set "LD3=300"
set /a "MB3=PX3*12/1048576"
set /a "BT3=PX3*30/1000000"
set /a "SC3=(70*4+95*3+(100-LD3)*2+100)/10"
if !SC3! gtr 100 set "SC3=100"

rem P4
set /a "PX4=1280*720"
set /a "LD4=PX4/20736"
set /a "MB4=PX4*12/1048576"
set /a "BT4=PX4*30/1000000"
set /a "SC4=(98*4+65*3+(100-LD4)*2+100)/10"
if !SC4! gtr 100 set "SC4=100"

rem Write table data to temp file
set "TBL=%TEMP%\adw_table.txt"
echo ^| # ^| Resolution ^| DPI ^| Codec ^| FPS ^| Mbps ^| Load ^| Mem ^| Smooth ^| Qual ^| Score ^|> "!TBL!"
echo ^| 1 ^| !R1! ^| 240 ^| h264 ^| 60 ^| !BT1! ^| !LD1!%% ^| !MB1! ^| 85 ^| 90 ^| !SC1! ^|>> "!TBL!"
if "!SKIP_P2!"=="0" echo ^| 2 ^| 1920x1080 ^| 240 ^| h264 ^| 60 ^| !BT2! ^| !LD2!%% ^| !MB2! ^| 90 ^| 85 ^| !SC2! ^|>> "!TBL!"
echo ^| 3 ^| 2560x1440 ^| 240 ^| h264 ^| 60 ^| !BT3! ^| !LD3!%% ^| !MB3! ^| 70 ^| 95 ^| !SC3! ^|>> "!TBL!"
echo ^| 4 ^| 1280x720 ^| 160 ^| h264 ^| 60 ^| !BT4! ^| !LD4!%% ^| !MB4! ^| 98 ^| 65 ^| !SC4! ^|>> "!TBL!"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%modules\table.ps1" "!TBL!"
echo.

rem === LAUNCH ===
set /p "SEL=  Profile [1-4] (default 1): "
if not defined SEL set "SEL=1"

if "!SEL!"=="1" (set "RES=!PC_W!x!PC_H!" & set "DPI=240")
if "!SEL!"=="2" (set "RES=1920x1080" & set "DPI=240")
if "!SEL!"=="3" (set "RES=2560x1440" & set "DPI=240")
if "!SEL!"=="4" (set "RES=1280x720" & set "DPI=160")

set "CMD=scrcpy -s !S! --new-display=!RES!/!DPI! --video-codec=h264 --max-fps=60 --video-bit-rate=8M --no-audio"

set /p "AUDIO=  Audio? (y/N): "
if /i "!AUDIO!"=="y" set "CMD=!CMD:--no-audio=!"

set /p "FREEFORM=  Multi-window? (y/N): "
if /i "!FREEFORM!"=="y" (
    adb -s !S! shell settings put global enable_freeform_support 1 >nul 2>&1
    adb -s !S! shell settings put global development_enable_freeform_windows_support 1 >nul 2>&1
    adb -s !S! shell settings put global force_allow_on_external 1 >nul 2>&1
    echo %CD%    Freeform: enabled%C0%
) else (
    adb -s !S! shell settings put global enable_freeform_support 0 >nul 2>&1
    adb -s !S! shell settings put global development_enable_freeform_windows_support 0 >nul 2>&1
    adb -s !S! shell settings put global force_allow_on_external 0 >nul 2>&1
    echo %CD%    Freeform: disabled%C0%
)

echo.
echo %C3%  Command:%C0% !CMD!
echo.
set /p "GO=  Launch? (Y/n): "
if /i "!GO!"=="n" goto :eof

!CMD!
echo.
pause
