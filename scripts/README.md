# scripts

> **Author:** Chittaranjan Baral ([@SJLNS](https://github.com/SJLNS))
> **Version:** v0.3.0
> **Last updated:** 2026-08-30

Build/dev tooling that isn't specific to one board.

## buildenv.sh

Structured build wrapper for the ZCU firmware targets. Generates every
intermediate compilation artifact into its own folder and writes a
sequenced, timestamped log per run. On failure it stops immediately with a
loud banner naming the failing step and the log file to check.

**Run from Git Bash (not cmd — this is a bash script), from the repo root:**

```bash
cd <path-to-repo-root>/SDV_Replica_POC
./scripts/buildenv.sh <zcu1-discovery|zcu2-nucleo|all> [clean]
```

Output lands in `build-output/<target>/` (gitignored — regenerated every run,
never committed):

```
build-output/<target>/
├── preprocessed/   .i files (macro-expanded source)
├── asm/            .s files (compiler-generated assembly + copy of startup.s)
├── obj/            .o files
├── elf/            linked .elf
├── bin/            raw .bin (for flashing)
├── map/            linker .map file
└── logs/           one timestamped build_YYYYMMDD_HHMMSS.log per run
```

Requires `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`, and `arm-none-eabi-size`
on `PATH` (see Execution Guide Section 2 for install steps).

## build_console.bat

cmd.exe-native, menu-driven build console covering **all 6 real modules** in
the repo — both ZCU firmware targets and all 4 HPC C++ services
(hpc-bridge/cloud-gateway × HPC-1/HPC-2). Complements buildenv.sh rather than
replacing it: buildenv.sh stays the Git-Bash tool for ZCU-only staged builds;
this is the broader, cmd-native console covering everything, HPC included.

**Run from cmd.exe (not Git Bash), from the repo root — double-click the file
in File Explorer, or from an open cmd window:**

```cmd
cd C:\Git_source\SDV_Replica_POC
scripts\build_console.bat
```

Menu options: clean/incremental build of all modules, ZCU-only, HPC-only, or
one specific module picked by number. Each module build reports its source
file count, a live `[COMPILING...]` status, and a final `PASS`/`FAIL` verdict
with its own timestamped log under:

```
Logs/Build/<module path>/build_YYYYMMDD_HHMMSS.log
```

A `BUILD SESSION VERDICT` summary listing every module built this run and its
result prints at the end of each menu action.

**Status: not yet run end-to-end successfully on real Windows at time of writing.**
The first real run (2026-08-30) failed on all 6 modules with `'cmake' is not
recognized` — CMake was never installed on that machine. Fixed in v2 with a
pre-flight tool check that catches this immediately (see below) rather than
burying it in per-module logs, plus a real fix for a source-count bug found in
the same run. The pre-flight check itself, and each individual `cmake`
command, are verified; the script's full menu flow end-to-end on Windows still
needs its first clean run to confirm.

**If the pre-flight check reports `cmake MISSING`:**

```powershell
winget install --id Kitware.CMake -e
```
Close and reopen the terminal afterward (same PATH-refresh reason as the ARM
toolchain install) before re-running `build_console.bat`.

**If it reports `g++ MISSING`** (needed for the 4 HPC C++ services — this
hasn't been confirmed present or absent on your machine yet, since the
previous run failed before ever reaching a compiler check): report back and
we'll sort out the right compiler install for your setup (MinGW-w64, LLVM, or
Visual Studio Build Tools) rather than guessing here.

Requires `cmake` and either `g++` (HPC modules) or `arm-none-eabi-gcc` (ZCU
modules) on the system `PATH`, plus PowerShell available for timestamp
generation (standard on Windows 10/11).

