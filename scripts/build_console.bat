@echo off
setlocal enabledelayedexpansion
REM ================================================================
REM  SDV_Replica_POC - Build & Compilation Console  (v4)
REM
REM  Run from cmd.exe (double-click, or from an open cmd window) -
REM  NOT Git Bash.
REM
REM  CHANGES IN v4 - the v3 bash-delegation approach is REMOVED:
REM   v3 tried to have this script call scripts\buildenv.sh via Git
REM   Bash's bash.exe, to get the same granular per-file staged output
REM   buildenv.sh produces. Across three real attempts this hit three
REM   different genuine bugs (a batch paren-nesting parser crash, a
REM   Windows-vs-POSIX path translation failure, and a second path
REM   translation failure even after converting to forward slashes) -
REM   each fixed individually, but the pattern itself (cmd.exe calling
REM   into bash.exe, crossing a Windows-path/POSIX-path boundary) kept
REM   producing new failure modes that could not be verified without a
REM   real Windows machine to test on.
REM
REM   v4 fixes this at the root: ZCU modules are now compiled with
REM   arm-none-eabi-gcc DIRECTLY from this batch file, staged exactly
REM   like buildenv.sh (preprocess -> compile to assembly -> compile
REM   to object, per source file, then link -> objcopy -> size) - with
REM   ZERO cross-shell calls and zero POSIX-path handling anywhere.
REM   Every path used is a plain Windows path throughout. This doesn't
REM   just fix the last bug - it removes the entire category of bug.
REM
REM   The per-file compile/link recipe below was verified directly
REM   against this repo's actual real source files (not stand-ins)
REM   before being included here - see the accompanying explanation.
REM
REM   The HPC C++ services are UNCHANGED - still plain CMake
REM   configure+build, since that path has never had a problem.
REM
REM  CHANGES IN v2 (fixing the 2026-08-30 first-run failures):
REM   - Pre-flight tool check (cmake / g++ / arm-none-eabi-gcc) runs
REM     before the menu, so a missing tool is obvious immediately.
REM   - Source count uses a dir+find idiom, not a for-loop counter.
REM   - ANSI colour output (VT100 escape codes).
REM
REM  STILL TRUE: this exact file has not been executed end-to-end on
REM  real Windows before being handed to you. The individual compiler/
REM  linker commands were verified directly against this repo's real
REM  source files in a Linux sandbox (proving the compile RECIPE is
REM  correct); the batch script wrapping them has not itself been run
REM  on Windows yet. Report back the exact on-screen output of
REM  anything that looks wrong.
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

REM --- ARM toolchain (used directly for ZCU modules - see v4 note above) ---
set "ARM_CC=arm-none-eabi-gcc"
set "ARM_OBJCOPY=arm-none-eabi-objcopy"
set "ARM_SIZE=arm-none-eabi-size"
set "ARM_CFLAGS=-mcpu=cortex-m4 -mthumb -mfloat-abi=soft -Wall -Wextra -ffreestanding -O0 -g"
set "ARM_CPUFLAGS=-mcpu=cortex-m4 -mthumb -mfloat-abi=soft"

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
  echo   cmake              !C_FAIL!MISSING!C_RESET!  - required for the 4 HPC C++ services
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

REM --- pick a CMake generator that actually matches an installed build tool (HPC modules only) ---
set "GENERATOR="
where ninja >nul 2>&1
if not errorlevel 1 (
  set "GENERATOR=Ninja"
  echo   build tool ^(ninja^)      !C_PASS!OK!C_RESET!
) else (
  where mingw32-make >nul 2>&1
  if not errorlevel 1 (
    set "GENERATOR=MinGW Makefiles"
    echo   build tool ^(mingw32-make^) !C_PASS!OK!C_RESET!
  ) else (
    where make >nul 2>&1
    if not errorlevel 1 (
      set "GENERATOR=MinGW Makefiles"
      echo   build tool ^(make^)       !C_PASS!OK!C_RESET!
    ) else (
      echo   build tool         !C_FAIL!MISSING!C_RESET!  - no ninja/mingw32-make/make found
      echo   !C_DIM!Install one:  winget install Ninja-build.Ninja!C_RESET!
      set "MISSING=1"
    )
  )
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

REM --- source count: dir+find idiom ---
set "SRC_COUNT=0"
if exist "!FULL_PATH!\src" (
  for /f %%N in ('dir /s /b "!FULL_PATH!\src\*.c" "!FULL_PATH!\src\*.cpp" "!FULL_PATH!\src\*.s" 2^>nul ^| find /c /v ""') do set "SRC_COUNT=%%N"
)
echo   Source count    : !SRC_COUNT! file(s)
echo !C_DIV!================================================================!C_RESET!

set "MODLOGDIR=!LOG_ROOT!\!MOD_PATH!"
if not exist "!MODLOGDIR!" mkdir "!MODLOGDIR!" >nul 2>&1

set "TS="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%T"
if "!TS!"=="" set "TS=nodate"
set "LOGFILE=!MODLOGDIR!\build_!TS!.log"

set "BUILD_OK=1"

if /i "!MOD_PATH:~0,4!"=="zcu\" (
  set "ZCU_TARGET=!MOD_PATH:zcu\=!"
  echo === Building !MOD_NAME! - %DATE% %TIME% === > "!LOGFILE!"
  call :COMPILE_ZCU !ZCU_TARGET! !MOD_MODE!
  if errorlevel 1 set "BUILD_OK=0"
) else (
  if /i "!MOD_MODE!"=="clean" (
    if exist "!FULL_PATH!\build" rmdir /s /q "!FULL_PATH!\build"
  )

  echo   !C_INFO![COMPILING...]!C_RESET!
  echo === Building !MOD_NAME! ^(!MOD_PATH!^) - %DATE% %TIME% === > "!LOGFILE!"

  if defined GENERATOR (
    cmake -G "!GENERATOR!" -S "!FULL_PATH!" -B "!FULL_PATH!\build" >> "!LOGFILE!" 2>&1
  ) else (
    cmake -S "!FULL_PATH!" -B "!FULL_PATH!\build" >> "!LOGFILE!" 2>&1
  )
  if errorlevel 1 set "BUILD_OK=0"

  if "!BUILD_OK!"=="1" (
    cmake --build "!FULL_PATH!\build" >> "!LOGFILE!" 2>&1
    if errorlevel 1 set "BUILD_OK=0"
  )
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
REM  Native, direct arm-none-eabi-gcc build for a ZCU target - no
REM  CMake, no bash, no cross-shell calls. Mirrors scripts\buildenv.sh
REM  step for step (preprocess -> assembly -> object per source file,
REM  then link -> objcopy -> size), using plain Windows paths only.
REM
REM  %1 = target name (zcu1-discovery | zcu2-nucleo)
REM  %2 = clean | incremental
REM
REM  Uses GOTO for error handling instead of nested if/else blocks -
REM  this is a deliberate choice after repeated batch parser issues
REM  with deeply nested parenthesized blocks elsewhere in this file.
:COMPILE_ZCU
set "ZT=%~1"
set "ZMODE=%~2"
set "ZDIR=!REPO_ROOT!\zcu\!ZT!"
set "ZOUT=!REPO_ROOT!\build-output\!ZT!"
set ZOBJS=

if /i "!ZMODE!"=="clean" if exist "!ZOUT!" rmdir /s /q "!ZOUT!"

if not exist "!ZOUT!\preprocessed" mkdir "!ZOUT!\preprocessed" >nul 2>&1
if not exist "!ZOUT!\asm" mkdir "!ZOUT!\asm" >nul 2>&1
if not exist "!ZOUT!\obj" mkdir "!ZOUT!\obj" >nul 2>&1
if not exist "!ZOUT!\obj\mcal" mkdir "!ZOUT!\obj\mcal" >nul 2>&1
if not exist "!ZOUT!\elf" mkdir "!ZOUT!\elf" >nul 2>&1
if not exist "!ZOUT!\bin" mkdir "!ZOUT!\bin" >nul 2>&1
if not exist "!ZOUT!\map" mkdir "!ZOUT!\map" >nul 2>&1

echo   !C_INFO![COMPILING...]!C_RESET!

REM ---- main.c (present on both ZCU targets) ----
call :ZCU_COMPILE_C "!ZDIR!" "!ZOUT!" "." main
if errorlevel 1 exit /b 1
set ZOBJS=!ZOBJS! "!ZOUT!\obj\main.o"

REM ---- target-specific extra sources ----
if /i "!ZT!"=="zcu1-discovery" (
  set "ZLD=STM32F407VG_FLASH.ld"

  call :ZCU_COMPILE_C "!ZDIR!" "!ZOUT!" "mcal" rcc_driver
  if errorlevel 1 exit /b 1
  set ZOBJS=!ZOBJS! "!ZOUT!\obj\mcal\rcc_driver.o"

  call :ZCU_COMPILE_C "!ZDIR!" "!ZOUT!" "mcal" gpio_driver
  if errorlevel 1 exit /b 1
  set ZOBJS=!ZOBJS! "!ZOUT!\obj\mcal\gpio_driver.o"
) else (
  set "ZLD=STM32F446RE_FLASH.ld"
)

REM ---- startup.s (present on both, always a plain assemble - no
REM      preprocess/assembly-generation stages, it already IS assembly) ----
"!ARM_CC!" !ARM_CPUFLAGS! -c "!ZDIR!\src\startup.s" -o "!ZOUT!\obj\startup.o" >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :ZCU_STEP_FAILED_startup
echo   !C_PASS!OK!C_RESET!  Assemble startup.s -^> object
set ZOBJS=!ZOBJS! "!ZOUT!\obj\startup.o"
goto :ZCU_STARTUP_DONE
:ZCU_STEP_FAILED_startup
echo   !C_FAIL![FAIL] Assemble startup.s!C_RESET!
exit /b 1
:ZCU_STARTUP_DONE

REM ---- link ----
"!ARM_CC!" !ARM_CPUFLAGS! -T"!ZDIR!\linker\!ZLD!" -nostdlib -Wl,--gc-sections -Wl,-Map="!ZOUT!\map\!ZT!.map" -o "!ZOUT!\elf\!ZT!.elf" !ZOBJS! >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :ZCU_STEP_FAILED_link
echo   !C_PASS!OK!C_RESET!  Link !ZT!.elf
goto :ZCU_LINK_DONE
:ZCU_STEP_FAILED_link
echo   !C_FAIL![FAIL] Link !ZT!.elf!C_RESET!
exit /b 1
:ZCU_LINK_DONE

REM ---- objcopy ----
"!ARM_OBJCOPY!" -O binary "!ZOUT!\elf\!ZT!.elf" "!ZOUT!\bin\!ZT!.bin" >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :ZCU_STEP_FAILED_bin
echo   !C_PASS!OK!C_RESET!  Generate !ZT!.bin
goto :ZCU_BIN_DONE
:ZCU_STEP_FAILED_bin
echo   !C_FAIL![FAIL] Generate !ZT!.bin!C_RESET!
exit /b 1
:ZCU_BIN_DONE

REM ---- size report ----
"!ARM_SIZE!" "!ZOUT!\elf\!ZT!.elf"
"!ARM_SIZE!" "!ZOUT!\elf\!ZT!.elf" >> "!LOGFILE!" 2>&1

exit /b 0

REM ================================================================
REM  Compile one C source file: preprocess, then assembly, then
REM  object - three separate steps, matching buildenv.sh exactly.
REM
REM  %1 = target dir (full path)     %2 = output dir (full path)
REM  %3 = subfolder under src\, or "." for none
REM  %4 = base filename, no extension
:ZCU_COMPILE_C
set "CDIR=%~1"
set "COUT=%~2"
set "CSUB=%~3"
set "CBASE=%~4"

if /i "!CSUB!"=="." (
  set "CSRC=!CDIR!\src\!CBASE!.c"
  set "CASM=!COUT!\asm\!CBASE!.s"
  set "CPRE=!COUT!\preprocessed\!CBASE!.i"
  set "COBJ=!COUT!\obj\!CBASE!.o"
) else (
  set "CSRC=!CDIR!\src\!CSUB!\!CBASE!.c"
  set "CASM=!COUT!\asm\!CBASE!.s"
  set "CPRE=!COUT!\preprocessed\!CBASE!.i"
  set "COBJ=!COUT!\obj\!CSUB!\!CBASE!.o"
)

"!ARM_CC!" !ARM_CFLAGS! -I"!CDIR!\inc" -E "!CSRC!" -o "!CPRE!" >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :CCOMPILE_FAILED_pre
echo   !C_PASS!OK!C_RESET!  Preprocess !CBASE!.c
goto :CCOMPILE_PRE_DONE
:CCOMPILE_FAILED_pre
echo   !C_FAIL![FAIL] Preprocess !CBASE!.c!C_RESET!
exit /b 1
:CCOMPILE_PRE_DONE

"!ARM_CC!" !ARM_CFLAGS! -I"!CDIR!\inc" -S "!CSRC!" -o "!CASM!" >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :CCOMPILE_FAILED_asm
echo   !C_PASS!OK!C_RESET!  Compile !CBASE!.c -^> assembly
goto :CCOMPILE_ASM_DONE
:CCOMPILE_FAILED_asm
echo   !C_FAIL![FAIL] Compile !CBASE!.c -^> assembly!C_RESET!
exit /b 1
:CCOMPILE_ASM_DONE

"!ARM_CC!" !ARM_CFLAGS! -I"!CDIR!\inc" -c "!CSRC!" -o "!COBJ!" >> "!LOGFILE!" 2>&1
if errorlevel 1 goto :CCOMPILE_FAILED_obj
echo   !C_PASS!OK!C_RESET!  Compile !CBASE!.c -^> object
exit /b 0
:CCOMPILE_FAILED_obj
echo   !C_FAIL![FAIL] Compile !CBASE!.c -^> object!C_RESET!
exit /b 1

REM ================================================================
:PRINT_VERDICT
echo.
echo !C_TITLE!================================================================!C_RESET!
echo !C_TITLE!  BUILD SESSION VERDICT!C_RESET!
echo !C_TITLE!================================================================!C_RESET!
set "VERDICT_LINES=0"
if exist "!SESSION_SUMMARY!" (
  for /f "usebackq delims=" %%L in ("!SESSION_SUMMARY!") do (
    set "LINE=%%L"
    set "VERDICT_LINES=1"
    if "!LINE:~0,6!"=="[PASS]" echo !C_PASS!!LINE!!C_RESET!
    if "!LINE:~0,6!"=="[FAIL]" echo !C_FAIL!!LINE!!C_RESET!
    if "!LINE:~0,6!"=="[SKIP]" echo !C_SKIP!!LINE!!C_RESET!
  )
)
if "!VERDICT_LINES!"=="0" echo   (no modules were built this session)
echo !C_TITLE!================================================================!C_RESET!
exit /b