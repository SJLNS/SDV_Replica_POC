@echo off
setlocal enabledelayedexpansion
REM ================================================================
REM  SDV_Replica_POC - Build & Compilation Console
REM
REM  Run from cmd.exe (double-click this file, or run from a cmd
REM  window) - NOT Git Bash. This is the cmd-native counterpart to
REM  scripts\buildenv.sh (which stays the Git Bash tool for ZCU-only
REM  staged builds). This console covers ALL 6 real modules in the
REM  repo: both ZCU firmware targets and all 4 HPC C++ services.
REM
REM  IMPORTANT - read before relying on this:
REM  This script could not be executed on real Windows before being
REM  handed to you (no Windows/cmd.exe available in the environment
REM  that wrote it). Every command inside it was verified individually
REM  (cmake configure/build, module paths, folder structure) but the
REM  script AS A WHOLE has not had a real end-to-end run on cmd.exe.
REM  Run it now and report back the exact on-screen output of the
REM  first thing that looks wrong - same debugging approach used for
REM  everything else in this project.
REM ================================================================

set "REPO_ROOT=%~dp0.."
pushd "%REPO_ROOT%"
set "REPO_ROOT=%CD%"
popd

set "LOG_ROOT=%REPO_ROOT%\Logs\Build"
set "SESSION_SUMMARY=%TEMP%\sdv_replica_poc_session_%RANDOM%.txt"

:MENU
cls
call :BANNER
echo ================================================================
echo   sdv_replica_poc / Build Console -- Build Menu
echo ================================================================
echo   1. Clean build           - ALL modules (ZCU + HPC)
echo   2. Incremental build     - ALL modules (ZCU + HPC)
echo   3. Zonal build (ZCU)     - incremental
echo   4. Zonal build (ZCU)     - clean
echo   5. HPC build             - incremental
echo   6. HPC build             - clean
echo   7. Specific module build - incremental
echo   8. Specific module build - clean
echo   9. Exit
echo ================================================================
set /p CHOICE="Enter choice [1-9]: "

if "!CHOICE!"=="1" (call :RUN_BUILD ALL clean) & goto MENU
if "!CHOICE!"=="2" (call :RUN_BUILD ALL incremental) & goto MENU
if "!CHOICE!"=="3" (call :RUN_BUILD ZCU incremental) & goto MENU
if "!CHOICE!"=="4" (call :RUN_BUILD ZCU clean) & goto MENU
if "!CHOICE!"=="5" (call :RUN_BUILD HPC incremental) & goto MENU
if "!CHOICE!"=="6" (call :RUN_BUILD HPC clean) & goto MENU
if "!CHOICE!"=="7" (call :SPECIFIC_MODULE incremental) & goto MENU
if "!CHOICE!"=="8" (call :SPECIFIC_MODULE clean) & goto MENU
if "!CHOICE!"=="9" goto :EOF
echo Invalid choice - pick a number from 1 to 9.
pause
goto MENU

REM ================================================================
:BANNER
echo ================================================================
echo                       SDV_Replica_POC
echo               Build ^& Compilation Console
echo               Project: sdv_replica_poc
echo    ZCU: STM32 Discovery/Nucleo   ^|   HPC: RPi5 / BBB services
echo ================================================================
exit /b

REM ================================================================
:RUN_BUILD
set "SCOPE=%~1"
set "MODE=%~2"
type nul > "!SESSION_SUMMARY!"
call :BANNER
if /i "!MODE!"=="clean" echo --clean requested: wiping build output for the selected module(s) first
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

echo ================================================================
echo   MODULE STARTED  : !MOD_NAME!
echo   Path            : !MOD_PATH!

if not exist "!FULL_PATH!" (
  echo   [SKIP] path not found - module folder does not exist
  echo [SKIP] !MOD_PATH! -- folder not found >> "!SESSION_SUMMARY!"
  echo ================================================================
  echo.
  exit /b
)

set SRC_COUNT=0
if exist "!FULL_PATH!\src" (
  for /r "!FULL_PATH!\src" %%f in (*.c *.cpp *.s) do set /a SRC_COUNT+=1
)
echo   Source count    : !SRC_COUNT! file(s)
echo ================================================================

if /i "!MOD_MODE!"=="clean" (
  if exist "!FULL_PATH!\build" rmdir /s /q "!FULL_PATH!\build"
)

set "MODLOGDIR=!LOG_ROOT!\!MOD_PATH!"
if not exist "!MODLOGDIR!" mkdir "!MODLOGDIR!" >nul 2>&1

set "TS="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%T"
if "!TS!"=="" set "TS=nodate"
set "LOGFILE=!MODLOGDIR!\build_!TS!.log"

echo   [COMPILING...]
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
  echo   VERDICT: PASS   ^(log: !LOGFILE!^)
  echo [PASS] !MOD_PATH! >> "!SESSION_SUMMARY!"
) else (
  echo.
  echo ################################################################
  echo ###  BUILD FAILED: !MOD_NAME!
  echo ###  See log: !LOGFILE!
  echo ################################################################
  echo.
  echo   VERDICT: FAIL
  echo [FAIL] !MOD_PATH! -- see !LOGFILE! >> "!SESSION_SUMMARY!"
)
echo.
exit /b

REM ================================================================
:PRINT_VERDICT
echo.
echo ================================================================
echo   BUILD SESSION VERDICT
echo ================================================================
if exist "!SESSION_SUMMARY!" (
  type "!SESSION_SUMMARY!"
) else (
  echo   (no modules were built this session)
)
echo ================================================================
exit /b
