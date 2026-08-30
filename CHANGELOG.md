# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [v0.3.3] - 2026-08-30

### Fixed
- `scripts/build_console.bat` — third real Windows run: all 6 modules now PASS
  (confirmed by screenshot), but the `BUILD SESSION VERDICT` summary at the end
  printed its header with an empty list underneath — no `[PASS]`/`[FAIL]` lines
  shown at all. Root cause: `findstr "[PASS]"` treats `[` and `]` as regex
  character-class syntax, not literal brackets, so the search pattern was
  actually "match a line starting with any one of the characters P, A, or S" —
  which never matched a line starting with a literal `[` character. Every
  summary line was silently skipped. Replaced with a substring comparison
  (`!LINE:~0,6!`) that checks the literal first 6 characters of each line
  against `[PASS]`/`[FAIL]`/`[SKIP]` directly — verified the indexing is
  correct for all three tags before shipping the fix.
- Verified: all 6 modules still build correctly (Ninja generator) after the
  change — this was a display-only bug, the actual build logic was untouched.

## [v0.3.2] - 2026-08-30

### Fixed
- `scripts/build_console.bat` — second real Windows run (after the v0.3.1 CMake
  install) failed on all 6 modules with `CMake Error ... Running 'nmake' '-?' failed
  with: no such file or directory`. Root cause: with no generator explicitly
  specified, CMake auto-selected the "NMake Makefiles" generator (needs Visual
  Studio's `nmake.exe`), which isn't installed/usable on this machine, instead of
  falling back to something compatible with the working `g++`/`arm-none-eabi-gcc`
  toolchain that the pre-flight check had already confirmed present. Fixed by
  detecting an actually-available build tool (Ninja preferred, MinGW Makefiles as
  fallback) during the pre-flight check and explicitly pinning it via `cmake -G`
  on every module build, instead of trusting CMake's auto-detection.
- Pre-flight check now also reports build-tool availability (`ninja` /
  `mingw32-make` / `make`) alongside `cmake`/`g++`/`arm-none-eabi-gcc`, with a
  direct `winget install Ninja-build.Ninja` suggestion if none are found.
- Verified: the affected `CMakeLists.txt` files build cleanly under an explicitly
  pinned generator (tested with Ninja) — confirms the fix mechanism is sound, not
  just a guess.

## [v0.3.1] - 2026-08-30

### Fixed
- `scripts/build_console.bat` — first real Windows run (all 6 modules) failed with
  `'cmake' is not recognized as an internal or external command` on every single
  module. Root cause: CMake was never installed on this machine at all — `buildenv.sh`
  never needed it (calls `arm-none-eabi-gcc` directly), so the gap was invisible until
  this script, which relies on CMake, exposed it. Not a code or repo problem. Fix is a
  local install (`winget install --id Kitware.CMake -e`), documented in
  `scripts/README.md`.
- `scripts/build_console.bat` — source file count showed `0 file(s)` for every module
  in the same run, including ones with real source files. Root cause: the v1 for-loop
  counting logic. Replaced with a `dir /s /b ... | find /c /v ""` count, a more
  reliable standard batch idiom.

### Added
- `scripts/build_console.bat` — pre-flight tool check (`cmake`, `g++`,
  `arm-none-eabi-gcc`) now runs automatically before the menu appears, so a missing
  tool is obvious immediately instead of discovered by reading 6 separate log files.
  Also selectable from the menu (option 9) to re-check anytime.
- `scripts/build_console.bat` — ANSI colour output (VT100 escape codes, native on
  Windows 10 1511+/11, no registry changes needed): magenta/yellow banner and section
  headers, cyan `[COMPILING...]`, bright green `PASS`, bright red `FAIL`. Deliberately
  a different palette from the cyan/green reference example this was styled after.

## [v0.3.0] - 2026-08-30

### Added
- Real C++ build scaffolding for all 4 HPC services: `hpc1-rpi5/dom0-services/hpc-bridge`,
  `hpc1-rpi5/dom0-services/cloud-gateway`, `hpc2-bbb/containers/hpc-bridge`,
  `hpc2-bbb/containers/cloud-gateway`. Each has a `CMakeLists.txt` (C++17) and a
  `src/main.cpp` skeleton with explicit TODOs for wiring in real gRPC/protobuf logic
  and mTLS 1.3 credentials. Verified: all 4 compile, link, and run cleanly with `g++`/
  CMake, each printing its own distinct identity - confirmed as 4 genuinely separate,
  correctly-wired skeletons, not one file copied four times.
- `scripts/build_console.bat` — a cmd.exe-native, menu-driven build console covering
  all 6 real modules (2 ZCU firmware targets + 4 HPC C++ services): clean/incremental
  builds scoped to all modules, ZCU-only, HPC-only, or a single specific module: each
  module run reports source-file count, live compiling status, a PASS/FAIL verdict
  with its own timestamped log under `Logs/Build/<module path>/`, and a build-session
  summary at the end. Complements `scripts/buildenv.sh` (which remains the Git-Bash,
  staged-artifact tool for the ZCU targets specifically) rather than replacing it.
  **Not yet run end-to-end on real Windows at time of writing — first real run still
  needed to confirm.**

### Fixed
- `.gitattributes` hardened to force LF line endings on every text/source/script file
  (`* text=auto eol=lf` plus explicit per-extension rules), after 46 files were found
  locally modified with zero real content changes — pure CRLF drift introduced by
  Windows checkout behavior. `.bat` files are the one deliberate exception (`eol=crlf`),
  matching native Windows batch-file convention.

## [v0.2.0] - 2026-08-08

### Added
- `scripts/buildenv.sh` — structured build wrapper for both ZCU firmware targets.
  Generates dedicated per-stage artifact folders (preprocessed `.i`, assembly `.s`,
  object `.o`, `.elf`, `.bin`, `.map`), writes a sequenced/timestamped log per run,
  and fails loudly (banner in terminal + log) on the first broken step rather than
  continuing. Verified against both a clean build and a deliberately broken source
  file to confirm the failure path actually triggers correctly.

## [v0.1.0] - 2026-08-08

### Added
- Initial project scaffold: full folder structure per the architecture doc.
- Working ZCU-1 / ZCU-2 firmware skeletons — compiled and linked successfully with
  `arm-none-eabi-gcc` (proves the cross-toolchain path before real HAL/driver code
  is layered in).
- `proto/hpc_bridge.proto` — shared gRPC contract for the HPC-1/HPC-2 bridge, verified
  to compile with `protoc`.
- `vss/vss_custom.vspec` — custom VSS signal tree extension for both ZCU branches.
- KUKSA Databroker `docker-compose.yml` for both HPC-1 and HPC-2.
- MQTT-to-KUKSA feeder skeleton (`feeder.py`) for both branches.
- PKI issuance script (`pki/scripts/issue.sh`) — verified end-to-end: generates a
  root CA, three scoped intermediate CAs (zcu-ca, hpc-ca, cloud-ca), and signed leaf
  certificates, with `openssl` self-signature verification passing.
- CI workflow (`.github/workflows/build.yml`): builds both ZCU firmware targets,
  validates docker-compose files, lints the proto contract, byte-compiles Python
  services.
- `docs/` — architecture plan, execution guide, and A3 system diagram (PDF + SVG).

### Known open items
- STM32 Discovery board's onboard Ethernet PHY not yet confirmed — see Execution
  Guide Section 3.1.
- QNX SDP release with confirmed Raspberry Pi 5 BSP support not yet identified —
  see Execution Guide Section 4.1 and the architecture doc's risk register.
- KUKSA Databroker's native mTLS (client-cert verification) vs TLS+JWT behavior not
  yet verified against the pinned version — see architecture doc, PKI section.
