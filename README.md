# SDV_Replica_POC

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

## Status

Hardware-corrected architecture locked in. Currently bringing up HPC-1 (Raspberry Pi 5,
Xen). See the execution guide's checklist for current progress.

## License

Apache 2.0 — see [LICENSE](LICENSE). Chosen to match Eclipse KUKSA, the project's core
middleware dependency.
