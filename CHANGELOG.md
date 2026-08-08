# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

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
