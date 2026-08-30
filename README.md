# SDV_Replica_POC

> **Author:** Chittaranjan Baral ([@SJLNS](https://github.com/SJLNS))
> **Version:** v0.4.0
> **Last updated:** 2026-08-30

A personal, hands-on replica of a Software-Defined Vehicle zonal architecture: two
zonal control units (STM32 Discovery, STM32 Nucleo) feeding two edge compute nodes
(Raspberry Pi 5 running Xen + QNX, BeagleBone Black running Yocto + Docker), bridged
to AWS and Azure respectively, all secured end-to-end with mutual TLS 1.3.

Not a production system — a learning project built to experience real SDV/zonal
concepts (VSS-based signal middleware, hypervisor partitioning, container isolation,
mTLS PKI, OTA, digital twin) as far as the hardware honestly allows.

## Start here

- [`docs/SDV_Replica_POC_Architecture_Plan.md`](docs/SDV_Replica_POC_Architecture_Plan.md) — the *why*: corrected architecture, protocol stack, phased plan
- [`docs/SDV_Replica_POC_Execution_Guide.md`](docs/SDV_Replica_POC_Execution_Guide.md) — the *how*: tool installation, HW validation, bring-up commands, BOM
- [`docs/diagrams/`](docs/diagrams/) — A3 system architecture reference sheet (PDF + SVG)

## Repo layout

```
zcu/            embedded C firmware for both zonal control units
hpc1-rpi5/      Xen + Dom0 services + QNX DomU workload
hpc2-bbb/       Yocto build layer + Docker service containers
cloud/          AWS and Azure gateway/backend services
proto/          shared gRPC contracts
vss/            custom Vehicle Signal Specification extension
pki/            root/intermediate CA + issuance scripts (generated key material is gitignored)
ota/            HPC (SOTA) and ZCU (FOTA) update tooling
test/           integration and hardware-in-the-loop tests
```

## Build tooling

- `scripts/buildenv.sh` — Git Bash, staged-artifact build wrapper for the two ZCU
  firmware targets (preprocessed/asm/obj/elf/bin/map, sequenced logs, loud failure
  banners).
- `scripts/build_console.bat` — cmd.exe-native, menu-driven build console covering
  all 6 real modules (2 ZCU + 4 HPC C++ services): clean/incremental, scoped to all
  modules, ZCU-only, HPC-only, or one specific module, each with its own timestamped
  log under `Logs/Build/`.

## Status

Hardware-corrected architecture locked in. C++ build scaffolding in place for all 4
HPC services (hpc-bridge, cloud-gateway, both branches) - proven to compile, link,
and run on a host machine; not yet cross-compiled for the actual RPi5/BBB target
architectures, and gRPC/protobuf logic not yet wired in (see TODOs in each `main.cpp`).
RPi5 Stage 1 hardware bring-up not yet started. See the execution guide's checklist
and `CHANGELOG.md` for current progress.

## License

Apache 2.0 — see [LICENSE](LICENSE). Chosen to match Eclipse KUKSA, the project's core
middleware dependency.
