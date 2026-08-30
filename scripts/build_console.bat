@echo off
setlocal enabledelayedexpansion
REM ================================================================
REM  SDV_Replica_POC - Build & Compilation Console  (v2)
REM
REM  Run from cmd.exe (double-click, or from an open cmd window) -
REM  NOT Git Bash. Complements scripts\buildenv.sh (Git Bash, ZCU-only,
REM  staged artifacts) with a cmd-native console covering all 6 real
REM  modules: both ZCU firmware targets and all 4 HPC C++ services.
REM
REM  CHANGES IN v2 (fixing the 2026-08-30 first-run failures):
REM   - Every module failed with 'cmake' is not recognized -> added a
REM     pre-flight tool check (cmake / g++ / arm-none-eabi-gcc) that
REM     runs BEFORE the menu, so a missing tool is obvious immediately
REM     instead of discovered by reading 6 separate log files.
REM   - Source count showed 0 file(s) for every module (a real bug in
REM     the v1 for-loop counting logic) -> replaced with a dir+find
REM     based count, a more reliable standard batch idiom.
REM   - Added ANSI colour output (VT100 escape codes - supported
REM     natively on Windows 10 1511+ / Windows 11 cmd.exe, no registry
REM     changes needed): magenta/yellow banner and headers, cyan for
REM     in-progress, bright green PASS, bright red FAIL - a distinct
REM     palette from the cyan/green reference example this was styled
REM     after, by request.
REM
REM  STILL TRUE: this script could not be executed on real Windows
REM  before being handed to you. The pre-flight check and per-module
REM  steps were each verified individually; report back the exact
REM  on-screen output of anything that still looks wrong.
REM ================================================================

REM --- build an ESC character for ANSI colour codes ---
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "C_RESET=!ESC![0m"
set "C_TITLE=!ESC![1;95m"
set "C_HEAD=!ESC![1;93m"
set "C_DIV=!ESC![36m"
set "C_INFO=!ESC![1;96m"
set "C_PASS=!ESC![1;92m"
set "C_FAIL=!ESC![1;91m"
set "C_SKIP=!ESC![1;33m"
set "C_DIM=!ESC![90m"

set "REPO_ROOT=%~dp0.."
pushd "%REPO_ROOT%"
set "REPO_ROOT=%CD%"
popd

set "LOG_ROOT=%REPO_ROOT%\Logs\Build"
set "SESSION_SUMMARY=%TEMP%\sdv_replica_poc_session_%RANDOM%.txt"

call :PREFLIGHT
goto MENU

REM ================================================================
:PREFLIGHT
cls
call :BANNER
echo !C_HEAD!================================================================!C_RESET!
echo !C_HEAD!  PRE-FLIGHT TOOL CHECK!C_RESET!
echo !C_HEAD!================================================================!C_RESET!
set "MISSING=0"

where cmake >nul 2>&1
if errorlevel 1 (
  echo   cmake              !C_FAIL!MISSING!C_RESET!  - required for every module, both ZCU and HPC
  set "MISSING=1"
) else (
  echo   cmake              !C_PASS!OK!C_RESET!
)

where g++ >nul 2>&1
if errorlevel 1 (
  echo   g++                !C_FAIL!MISSING!C_RESET!  - required for the 4 HPC C++ services
  set "MISSING=1"
) else (
  echo   g++                !C_PASS!OK!C_RESET!
)

where arm-none-eabi-gcc >nul 2>&1
if errorlevel 1 (
  echo   arm-none-eabi-gcc  !C_FAIL!MISSING!C_RESET!  - required for the 2 ZCU firmware targets
  set "MISSING=1"
) else (
  echo   arm-none-eabi-gcc  !C_PASS!OK!C_RESET!
)

echo !C_HEAD!================================================================!C_RESET!
if "!MISSING!"=="1" (
  echo !C_FAIL!One or more required tools are missing - see above.!C_RESET!
  echo !C_DIM!Module builds needing a missing tool will fail immediately;!C_RESET!
  echo !C_DIM!this is expected until the missing tool is installed.!C_RESET!
) else (
  echo !C_PASS!All required tools found.!C_RESET!
)
echo.
pause
exit /b

REM ================================================================
:MENU
cls
call :BANNER
echo !C_HEAD!================================================================!C_RESET!
echo !C_HEAD!  sdv_replica_poc / Build Console -- Build Menu!C_RESET!
echo !C_HEAD!================================================================!C_RESET!
echo   1. Clean build           - ALL modules (ZCU + HPC)
echo   2. Incremental build     - ALL modules (ZCU + HPC)
echo   3. Zonal build (ZCU)     - incremental
echo   4. Zonal build (ZCU)     - clean
echo   5. HPC build             - incremental
echo   6. HPC build             - clean
echo   7. Specific module build - incremental
echo   8. Specific module build - clean
echo   9. Re-run pre-flight tool check
echo   0. Exit
echo !C_HEAD!================================================================!C_RESET!
set /p CHOICE="Enter choice [0-9]: "

if "!CHOICE!"=="1" (call :RUN_BUILD ALL clean) & goto MENU
if "!CHOICE!"=="2" (call :RUN_BUILD ALL incremental) & goto MENU
if "!CHOICE!"=="3" (call :RUN_BUILD ZCU incremental) & goto MENU
if "!CHOICE!"=="4" (call :RUN_BUILD ZCU clean) & goto MENU
if "!CHOICE!"=="5" (call :RUN_BUILD HPC incremental) & goto MENU
if "!CHOICE!"=="6" (call :RUN_BUILD HPC clean) & goto MENU
if "!CHOICE!"=="7" (call :SPECIFIC_MODULE incremental) & goto MENU
if "!CHOICE!"=="8" (call :SPECIFIC_MODULE clean) & goto MENU
if "!CHOICE!"=="9" (call :PREFLIGHT) & goto MENU
if "!CHOICE!"=="0" goto :EOF
echo Invalid choice - pick a number from 0 to 9.
pause
goto MENU

REM ================================================================
:BANNER
echo !C_TITLE!================================================================!C_RESET!
echo !C_TITLE!                      SDV_Replica_POC!C_RESET!
echo !C_TITLE!              Build ^& Compilation Console!C_RESET!
echo !C_TITLE!              Project: sdv_replica_poc!C_RESET!
echo !C_DIM!   ZCU: STM32 Discovery/Nucleo   ^|   HPC: RPi5 / BBB services!C_RESET!
echo !C_TITLE!================================================================!C_RESET!
exit /b

REM ================================================================
:RUN_BUILD
set "SCOPE=%~1"
set "MODE=%~2"
type nul > "!SESSION_SUMMARY!"
call :BANNER
if /i "!MODE!"=="clean" echo !C_DIM!--clean requested: wiping build output for the selected module(s) first!C_RESET!
echo.
echo Build scope: !SCOPE!   Mode: !MODE!
echo.

if /i "!SCOPE!"=="ALL" (
  call :BUILD_MODULE "ZCU1_Discovery"     "zcu\zcu1-discovery"                       "!MODE!"
  call :BUILD_MODULE "ZCU2_Nucleo"        "zcu\zcu2-nucleo"                          "!MODE!"
  call :BUILD_MODULE "HPC1_HpcBridge"     "hpc1-rpi5\dom0-services\hpc-bridge"       "!MODE!"
  call :BUILD_MODULE "HPC1_CloudGateway"  "hpc1-rpi5\dom0-services\cloud-gateway"    "!MODE!"
  call :BUILD_MODULE "HPC2_HpcBridge"     "hpc2-bbb\containers\hpc-bridge"           "!MODE!"
  call :BUILD_MODULE "HPC2_CloudGateway"  "hpc2-bbb\containers\cloud-gateway"        "!MODE!"
)
if /i "!SCOPE!"=="ZCU" (
  call :BUILD_MODULE "ZCU1_Discovery"     "zcu\zcu1-discovery"                       "!MODE!"
  call :BUILD_MODULE "ZCU2_Nucleo"        "zcu\zcu2-nucleo"                          "!MODE!"
)
if /i "!SCOPE!"=="HPC" (
  call :BUILD_MODULE "HPC1_HpcBridge"     "hpc1-rpi5\dom0-services\hpc-bridge"       "!MODE!"
  call :BUILD_MODULE "HPC1_CloudGateway"  "hpc1-rpi5\dom0-services\cloud-gateway"    "!MODE!"
  call :BUILD_MODULE "HPC2_HpcBridge"     "hpc2-bbb\containers\hpc-bridge"           "!MODE!"
  call :BUILD_MODULE "HPC2_CloudGateway"  "hpc2-bbb\containers\cloud-gateway"        "!MODE!"
)

call :PRINT_VERDICT
pause
exit /b

REM ================================================================
:SPECIFIC_MODULE
set "MODE=%~1"
call :BANNER
echo Available modules:
echo   1. ZCU1_Discovery        (zcu\zcu1-discovery)
echo   2. ZCU2_Nucleo           (zcu\zcu2-nucleo)
echo   3. HPC1_HpcBridge        (hpc1-rpi5\dom0-services\hpc-bridge)
echo   4. HPC1_CloudGateway     (hpc1-rpi5\dom0-services\cloud-gateway)
echo   5. HPC2_HpcBridge        (hpc2-bbb\containers\hpc-bridge)
echo   6. HPC2_CloudGateway     (hpc2-bbb\containers\cloud-gateway)
set /p MSEL="Select module [1-6]: "
type nul > "!SESSION_SUMMARY!"

if "!MSEL!"=="1" call :BUILD_MODULE "ZCU1_Discovery"    "zcu\zcu1-discovery"                    "!MODE!"
if "!MSEL!"=="2" call :BUILD_MODULE "ZCU2_Nucleo"       "zcu\zcu2-nucleo"                       "!MODE!"
if "!MSEL!"=="3" call :BUILD_MODULE "HPC1_HpcBridge"    "hpc1-rpi5\dom0-services\hpc-bridge"    "!MODE!"
if "!MSEL!"=="4" call :BUILD_MODULE "HPC1_CloudGateway" "hpc1-rpi5\dom0-services\cloud-gateway" "!MODE!"
if "!MSEL!"=="5" call :BUILD_MODULE "HPC2_HpcBridge"    "hpc2-bbb\containers\hpc-bridge"        "!MODE!"
if "!MSEL!"=="6" call :BUILD_MODULE "HPC2_CloudGateway" "hpc2-bbb\containers\cloud-gateway"     "!MODE!"

call :PRINT_VERDICT
pause
exit /b

REM ================================================================
REM  %1 = module name (display only)
REM  %2 = module path, relative to repo root, backslashes
REM  %3 = clean | incremental
:BUILD_MODULE
set "MOD_NAME=%~1"
set "MOD_PATH=%~2"
set "MOD_MODE=%~3"
set "FULL_PATH=!REPO_ROOT!\!MOD_PATH!"

echo !C_DIV!================================================================!C_RESET!
echo !C_HEAD!  MODULE STARTED  : !MOD_NAME!!C_RESET!
echo   Path            : !MOD_PATH!

if not exist "!FULL_PATH!" (
  echo   !C_SKIP![SKIP] path not found - module folder does not exist!C_RESET!
  echo [SKIP] !MOD_PATH! -- folder not found >> "!SESSION_SUMMARY!"
  echo !C_DIV!================================================================!C_RESET!
  echo.
  exit /b
)

REM --- source count: dir+find idiom, more reliable than a for-loop counter ---
set "SRC_COUNT=0"
if exist "!FULL_PATH!\src" (
  for /f %%N in ('dir /s /b "!FULL_PATH!\src\*.c" "!FULL_PATH!\src\*.cpp" "!FULL_PATH!\src\*.s" 2^>nul ^| find /c /v ""') do set "SRC_COUNT=%%N"
)
echo   Source count    : !SRC_COUNT! file(s)
echo !C_DIV!================================================================!C_RESET!

if /i "!MOD_MODE!"=="clean" (
  if exist "!FULL_PATH!\build" rmdir /s /q "!FULL_PATH!\build"
)

set "MODLOGDIR=!LOG_ROOT!\!MOD_PATH!"
if not exist "!MODLOGDIR!" mkdir "!MODLOGDIR!" >nul 2>&1

set "TS="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%T"
if "!TS!"=="" set "TS=nodate"
set "LOGFILE=!MODLOGDIR!\build_!TS!.log"

echo   !C_INFO![COMPILING...]!C_RESET!
echo === Building !MOD_NAME! ^(!MOD_PATH!^) - %DATE% %TIME% === > "!LOGFILE!"

set "BUILD_OK=1"
cmake -S "!FULL_PATH!" -B "!FULL_PATH!\build" >> "!LOGFILE!" 2>&1
if errorlevel 1 set "BUILD_OK=0"

if "!BUILD_OK!"=="1" (
  cmake --build "!FULL_PATH!\build" >> "!LOGFILE!" 2>&1
  if errorlevel 1 set "BUILD_OK=0"
)

if "!BUILD_OK!"=="1" (
  echo   MODULE COMPLETED: !MOD_NAME!
  echo   VERDICT: !C_PASS!PASS!C_RESET!   ^(log: !LOGFILE!^)
  echo [PASS] !MOD_PATH! >> "!SESSION_SUMMARY!"
) else (
  echo.
  echo !C_FAIL!################################################################!C_RESET!
  echo !C_FAIL!###  BUILD FAILED: !MOD_NAME!!C_RESET!
  echo !C_FAIL!###  See log: !LOGFILE!!C_RESET!
  echo !C_FAIL!################################################################!C_RESET!
  echo.
  echo   VERDICT: !C_FAIL!FAIL!C_RESET!
  echo [FAIL] !MOD_PATH! -- see !LOGFILE! >> "!SESSION_SUMMARY!"
)
echo.
exit /b

REM ================================================================
:PRINT_VERDICT
echo.
echo !C_TITLE!================================================================!C_RESET!
echo !C_TITLE!  BUILD SESSION VERDICT!C_RESET!
echo !C_TITLE!================================================================!C_RESET!
if exist "!SESSION_SUMMARY!" (
  for /f "usebackq delims=" %%L in ("!SESSION_SUMMARY!") do (
    set "LINE=%%L"
    echo !LINE! | findstr /b "[PASS]" >nul && echo !C_PASS!%%L!C_RESET!
    echo !LINE! | findstr /b "[FAIL]" >nul && echo !C_FAIL!%%L!C_RESET!
    echo !LINE! | findstr /b "[SKIP]" >nul && echo !C_SKIP!%%L!C_RESET!
  )
) else (
  echo   (no modules were built this session)
)
echo !C_TITLE!================================================================!C_RESET!
exit /b
