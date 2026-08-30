# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

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
