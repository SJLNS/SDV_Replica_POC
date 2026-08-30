# SDV_Replica_POC — System Architecture & Execution Plan

Status: hardware-corrected, ready to build
Scope: personal learning POC, not a production/safety-rated system

---

## 1. Purpose

Build a small but honest replica of a Software-Defined Vehicle zonal architecture: two
zonal control units (ZCUs) each driving sensors/actuators, feeding two HPCs over
Ethernet, the two HPCs cross-linked, and each HPC bridging to a different cloud (AWS /
Azure). Every hop is filtered and mutually authenticated. This document is the build
plan, corrected against what the four boards you own can actually do.

---

## 2. Final Corrected Architecture

| Node | Board | Role | OS / Isolation | Cloud |
|---|---|---|---|---|
| ZCU-1 | STM32 Discovery | sensor/actuator I/O | Embedded C, bare-metal or FreeRTOS | — |
| ZCU-2 | STM32 Nucleo | sensor/actuator I/O | Embedded C, bare-metal or FreeRTOS | — |
| HPC-1 | Raspberry Pi 5 (16GB) | edge compute, gateway | Xen: Dom0 (Linux, 1 core) + DomU (QNX eval, 3 cores) | AWS |
| HPC-2 | BeagleBone Black Rev C | edge compute, gateway | Yocto Linux (native, single core) + Docker containers | Azure |

**Corrections carried over from the last round** (do not re-litigate these — they are
hardware facts, not preferences):
- Jailhouse cannot run on the BBB (Cortex-A8 has no virtualization extensions). BBB
  isolation story = Docker/OCI containers + cgroups/namespaces, not a type-1 hypervisor.
- BBB is single-core; no core partitioning is possible there.
- RPi5 gets the only real hypervisor (Xen): 1 core → Dom0 control plane, 3 cores → QNX
  DomU workload — this is where your "3 cores" intent actually lands.
- STM32 Discovery Ethernet is unconfirmed — plan the firmware against an abstract
  network interface (see §6, Phase 1) so swapping in a W5500 SPI-Ethernet module later
  doesn't touch application logic.

**Physical topology** (only real Ethernet links — no direct ZCU-to-ZCU or
HPC-to-far-cloud wiring exists):

```
AWS  ── mTLS/gRPC ──  HPC-1 (RPi5)  ── mTLS/gRPC ──  HPC-2 (BBB)  ── mTLS/gRPC ──  Azure
                          │  MQTT+mTLS                   │  MQTT+mTLS
                       ZCU-1 (Discovery)              ZCU-2 (Nucleo)
                          │                               │
                    sensors/actuators A            sensors/actuators B
```

**Logical routing** (what actually satisfies "any sensor to any cloud and back"): a
signal from ZCU-1 can reach Azure by hopping ZCU-1→HPC-1→HPC-2→Azure over the Ethernet
backbone. This is why the HPC-1↔HPC-2 link matters as much as the cloud uplinks — it's
your only cross-branch path, and it's also your natural place to apply cross-domain
filtering.

**Filtering points** (two layers, as you specified):
- **Zonal level**: the ZCU firmware only publishes the MQTT topics it's authorized for,
  and only accepts actuation commands on topics it explicitly subscribes to. This is
  allow-list based, defined at compile time for the POC.
- **HPC level**: implemented as KUKSA VSS subtree scoping — each HPC's databroker
  exposes only a defined signal subtree to the other HPC and to its cloud, via gRPC
  channel-level access rules (or a thin authorization sidecar if the databroker version
  you're on doesn't support fine-grained scoping natively — verify this in Phase 5).

---

## 3. Technology Stack Matrix

| Layer | Technology | Rationale |
|---|---|---|
| ZCU firmware | Embedded C, FreeRTOS (recommended over bare-metal once you add TLS + MQTT) | mbedTLS + MQTT client are easiest to reason about with an RTOS scheduler |
| ZCU ↔ HPC | MQTT 3.1.1/5 over TLS 1.3, mutual auth | mature Cortex-M libraries exist; gRPC/DDS are too heavy for the MCU |
| ZCU security | mbedTLS (client cert + key, verify HPC server cert) | de facto standard embedded TLS stack, actively maintained |
| HPC middleware | Eclipse KUKSA Databroker (Docker container), VSS signal tree | resource-efficient, gRPC-native, standards-based schema (replaces S-CORE) |
| ZCU→VSS bridge | custom MQTT-to-KUKSA feeder process (Python or Rust) per HPC | the standard KUKSA "provider" integration pattern |
| HPC ↔ HPC | gRPC (protobuf) over mTLS 1.3 | both ends are full Linux/QNX network stacks — gRPC's natural home |
| HPC ↔ Cloud | gRPC or HTTPS/JSON over mTLS 1.3 | gRPC for structured telemetry/commands, JSON/HTTPS for dashboards/logging tooling |
| HPC-2 isolation | Docker / OCI containers, cgroups, namespaces | only isolation model the BBB's CPU supports |
| HPC-1 isolation | Xen (Dom0 Linux + QNX DomU) | only board with virtualization extensions |
| PKI | Private root CA + per-device leaf certs (step-ca or OpenSSL) | needed for mutual TLS across 4 boards + 2 cloud endpoints |
| Cloud | AWS IoT Core (HPC-1), Azure IoT Hub (HPC-2) | native mTLS device-cert support on both |
| OTA (HPC) | Docker image versioning + A/B rootfs partitions (Yocto swupdate / Mender for BBB; container re-pull for RPi5 Dom0) | realistic scope for Linux/QNX hosts |
| OTA (ZCU) | separate MCU bootloader project (dual-bank flash + signed image) | real, but budget it as its own sub-effort, not a Phase 1 dependency |
| Digital Twin | cloud-side state mirror, updated from VSS telemetry | scoped down from a full simulation twin |
| Voice UI | thin client → cloud intent API → gRPC command down to HPC | not embedded on the MCUs |
| Digital Key | short-lived signed token / cert-based challenge-response, cloud-issued | POC-scope authentication demo, not a full UWB/BLE key stack |

---

## 4. Repository / Folder Structure

```
SDV_Replica_POC/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── requirements.md              # see §7
│   ├── risk_register.md
│   └── diagrams/
├── pki/
│   ├── root-ca/
│   ├── intermediate-ca/
│   │   ├── zcu-ca/
│   │   ├── hpc-ca/
│   │   └── cloud-ca/
│   ├── scripts/                     # issue.sh, revoke.sh, rotate.sh
│   └── certs/                       # generated, gitignored
├── vss/
│   ├── vss_custom.vspec             # base VSS + your custom branches
│   └── vss.json                     # generated
├── zcu/
│   ├── zcu1-discovery/
│   │   ├── src/
│   │   ├── inc/
│   │   ├── drivers/                 # sensor/actuator HAL
│   │   ├── net/                     # MQTT client, TLS wrapper
│   │   └── CMakeLists.txt
│   └── zcu2-nucleo/                 # mirrors zcu1 structure
├── hpc1-rpi5/
│   ├── xen/
│   │   ├── dom0-config/
│   │   └── domu-qnx-config/
│   ├── dom0-services/
│   │   ├── kuksa-databroker/        # docker-compose
│   │   ├── mqtt-feeder/             # ZCU1 -> VSS bridge
│   │   ├── hpc-bridge/              # gRPC to HPC-2
│   │   └── cloud-gateway/           # gRPC/HTTPS to AWS
│   └── qnx-domu/
│       └── predictive-analytics/    # compute workload
├── hpc2-bbb/
│   ├── yocto/
│   │   ├── meta-sdvreplica/         # custom layer
│   │   └── local.conf.sample
│   └── containers/
│       ├── kuksa-databroker/
│       ├── mqtt-feeder/             # ZCU2 -> VSS bridge
│       ├── hpc-bridge/              # gRPC to HPC-1
│       └── cloud-gateway/           # gRPC/HTTPS to Azure
├── cloud/
│   ├── aws/
│   │   ├── iot-core/                # thing policies, cert provisioning
│   │   └── services/                # telemetry ingest, digital twin, command API
│   └── azure/
│       ├── iot-hub/
│       └── services/
├── proto/                           # shared .proto contracts (versioned)
├── ota/
│   ├── hpc-ota/                     # image build + rollout scripts
│   └── zcu-ota/                     # bootloader + signed image tooling
├── voice-ui/
├── digital-key/
└── test/
    ├── integration/
    └── hil/                         # hardware-in-the-loop scripts
```

---

## 5. PKI / mTLS 1.3 Design

1. **Root CA** — offline, only used to sign intermediates. Generate once, store the key
   outside the repo.
2. **Three intermediate CAs**: `zcu-ca`, `hpc-ca`, `cloud-ca` — this lets you scope trust
   (e.g. HPCs don't need to trust random ZCU leaf certs directly, only the zcu-ca).
3. **Leaf certs**: one per device (ZCU-1, ZCU-2, HPC-1, HPC-2) plus one per cloud gateway
   endpoint. Short-lived for the cloud-facing ones if you want to practice rotation.
4. **Tooling**: `step-ca` for anything past a first pass (gives you an ACME-like issuance
   flow you can automate); plain `openssl req`/`openssl ca` is fine for the very first
   bring-up.
5. **Verify before you build on it**: confirm whether your KUKSA Databroker version
   verifies client certificates natively (true mTLS) or only does server-side TLS + JWT.
   If it's the latter, put a TLS-terminating sidecar (nginx/envoy configured for client
   cert verification) in front of it and let JWT handle the application-layer identity
   behind that boundary. Don't assume — check the docs for the version you pin.

---

## 6. Phase-by-Phase Build & Execution Plan

Each phase lists **goal → prerequisites → steps → exit criteria**. Phases are ordered so
each one is independently testable before you wire it to the next.

### Phase 0 — Workstation & toolchain setup

- Goal: one dev machine that can build for all four targets.
- Steps:
  1. Install `arm-none-eabi-gcc` toolchain + STM32CubeIDE (or CubeMX + your own
     Makefile/CMake) for the ZCU firmware.
  2. Install Docker + Docker Compose on the dev machine (used to prototype the
     containerized services before deploying to HPC-2, and to run KUKSA locally).
  3. Set up a Yocto build environment (`git clone` poky + your BSP layer for AM335x —
     `meta-ti`) for HPC-2.
  4. Set up cross-build tooling for Xen (ARM64 target) and a Debian/Ubuntu ARM64 rootfs
     for RPi5 Dom0.
  5. Obtain the QNX non-commercial/eval SDP and BSP for the target you're using (verify
     RPi5 BSP support in the QNX SDP version you download — this varies by release).
  6. `git init` the repo using the folder structure in §4.
- Exit criteria: you can build a "hello world" for each of the four targets and flash/
  deploy it.

### Phase 1 — ZCU firmware bring-up (no networking yet)

- Goal: each STM32 board reads its sensors and drives its actuators locally.
- Steps:
  1. Bring up GPIO/ADC/PWM drivers for whatever sensors/actuators/relays you've wired.
  2. Add FreeRTOS with a sensor-poll task and an actuator-command task communicating via
     a queue — this task boundary is where the network layer plugs in later.
  3. Bench-test each sensor/actuator in isolation (multimeter/scope, not just serial
     print) before trusting the data.
- Exit criteria: ZCU-1 and ZCU-2 each print live sensor values over UART/serial console
  and respond to a hardcoded actuation command.

### Phase 2 — HPC-1 bring-up (RPi5: Xen + Dom0 + QNX DomU)

- Steps:
  1. Flash a minimal Debian/Ubuntu ARM64 image, confirm the board boots standalone
     first — don't debug Xen and hardware bring-up simultaneously.
  2. Build/install Xen for aarch64, configure Dom0 with 1 vCPU pinned.
  3. Create the QNX DomU config, pin it to 3 vCPUs, boot it as a guest.
  4. Confirm Dom0 ↔ DomU can talk over a virtual network interface (xen-netfront/back or
     equivalent) before adding anything else.
- Exit criteria: `xl list` shows Dom0 and the QNX DomU running, and you can ping between
  them.

### Phase 3 — HPC-2 bring-up (BBB: Yocto + Docker)

- Steps:
  1. Build a minimal `core-image-minimal` (or your own custom image) with `meta-ti` for
     AM335x, flash to eMMC/SD, confirm boot.
  2. Add Docker support to your Yocto layer (`meta-virtualization`), rebuild, confirm
     `docker run hello-world` works on-device.
  3. Given 512MB RAM, keep container images minimal — Alpine-based where possible, and
     watch memory headroom closely once KUKSA + feeder + bridge are all running.
- Exit criteria: BBB boots Yocto and runs a Docker container standalone.

### Phase 4 — Network & PKI bring-up

- Steps:
  1. Wire the physical topology from §2 — ZCU1↔HPC1, ZCU2↔HPC2, HPC1↔HPC2 Ethernet.
  2. Issue leaf certs (per §5) to all four boards.
  3. Prove mutual TLS 1.3 end-to-end with the simplest possible test first: a bare
     `openssl s_server`/`s_client` mTLS handshake between HPC-1 and HPC-2 before any
     application protocol rides on top.
- Exit criteria: mTLS handshake succeeds between every real link in the topology, with a
  self-signed/wrong cert correctly rejected as a negative test.

### Phase 5 — KUKSA Databroker + VSS model

- Steps:
  1. Define your VSS extension (`vss/vss_custom.vspec`) — extend the standard tree with
     branches for your specific motors/relays/contactors.
  2. Run KUKSA Databroker in Docker on both HPCs:
     `docker run --rm -it -p 55555:55555 -v $(pwd)/vss:/vss ghcr.io/eclipse-kuksa/kuksa-databroker:main --vss /vss/vss.json --tls-cert ... --tls-private-key ...`
  3. Confirm TLS/mTLS behavior per the note in §5 before moving on.
  4. Smoke-test with `kuksa-client` (Python SDK) locally: set a value, subscribe, confirm
     round-trip.
- Exit criteria: both HPCs run a databroker with your custom VSS tree loaded, reachable
  over TLS.

### Phase 6 — ZCU ↔ HPC MQTT integration

- Steps:
  1. Add an MQTT client + mbedTLS to the ZCU firmware, pointed at an MQTT broker running
     on the HPC (Mosquitto is fine as the on-HPC broker, containerized).
  2. Write the MQTT-to-KUKSA feeder process on each HPC: subscribes to the ZCU's topics,
     writes into the local VSS tree; subscribes to VSS actuation targets, publishes MQTT
     commands back down to the ZCU.
  3. Verify with the mTLS negative test again at this layer — a client without a valid
     cert must be rejected by the broker.
- Exit criteria: a sensor reading on ZCU-1 appears in HPC-1's VSS tree within your target
  latency, and an actuation command set via `kuksa-client` reaches the ZCU-1 relay/motor.

### Phase 7 — HPC ↔ HPC gRPC bridge

- Steps:
  1. Define the shared `.proto` contract for cross-HPC signal exchange (`proto/`).
  2. Implement the bridge service: subscribes to a defined VSS subtree on its local
     databroker, republishes into the peer's tree over mTLS gRPC — this is your
     HPC-level filter, implemented as "only these paths cross this bridge."
  3. Test both directions: ZCU-1 data visible (filtered) on HPC-2's tree, and vice versa.
- Exit criteria: a signal originating at ZCU-1 is observable, correctly filtered, on
  HPC-2 — proving the "any sensor to any cloud" path works end to end short of cloud.

### Phase 8 — Cloud connectivity (AWS IoT Core / Azure IoT Hub)

- Steps:
  1. Provision an AWS IoT Core Thing + cert for HPC-1, an Azure IoT Hub device identity +
     cert for HPC-2 (both support X.509 device certs, so your existing PKI plugs in
     directly — issue cloud-facing leaf certs from `cloud-ca`).
  2. Write the cloud-gateway service per HPC: subscribes to its local (filtered) VSS
     subtree, republishes to the respective cloud; subscribes to cloud-side commands,
     writes back to the local VSS tree as actuation targets.
  3. Stand up a minimal cloud-side service (Lambda/Functions or a small always-on
     service) that ingests telemetry and can issue a command back down — this doubles as
     your Digital Twin backend in Phase 10.
- Exit criteria: a ZCU-1 sensor value is visible in an AWS dashboard/log, and a command
  issued from AWS reaches a ZCU-1 actuator; same for the ZCU-2/Azure branch.

### Phase 9 — OTA (HPC layer first)

- Steps:
  1. HPC-1: version your Docker images (Dom0 services) and QNX DomU images; roll updates
     by pulling a new tag and restarting the container/guest, with a rollback tag kept.
  2. HPC-2: adopt Mender or swupdate for A/B rootfs updates on the BBB, since Yocto has
     first-class support for both.
  3. Treat ZCU firmware OTA (SOTA/FOTA over the MQTT link, dual-bank flash, signed
     images) as its own sub-project — don't block the rest of the plan on it.
- Exit criteria: you can push a new container image tag to an HPC and have it deploy
  without a manual re-flash, with a working rollback path.

### Phase 10 — Digital Twin, Voice UI, Digital Key, Predictive Analytics

- Digital Twin: cloud service maintains a live mirrored state from VSS telemetry;
  a simple web dashboard reading that state is enough for the POC.
- Voice UI: a thin client (phone/laptop) doing wake-word + intent recognition, calling
  your cloud command API, which flows back down through the same gRPC path as any other
  actuation command — no new hardware-side protocol needed.
- Digital Key: cloud-issued short-lived signed token, validated by the HPC before it
  will accept a "high-privilege" actuation command (e.g. unlock-equivalent action on
  your relay setup) — demonstrates the concept without a full UWB/BLE ranging stack.
- Predictive analytics: run on the QNX DomU (HPC-1) since that's the workload it was
  reserved for — a simple model (threshold/trend detection to start, a small trained
  model later) consuming the VSS stream and writing predictions back as new VSS signals.
- Exit criteria: each is demonstrable end-to-end, scoped exactly as described above —
  resist the urge to expand scope here; these are stretch demos, not the core proof.

### Phase 11 — Testing, validation, demo script

- Steps:
  1. Integration tests per link (already exercised as exit criteria above) — collect
     them into `test/integration/`.
  2. Hardware-in-the-loop smoke test: power-cycle everything from cold, confirm the full
     chain (sensor → ZCU → HPC → cloud → HPC → ZCU → actuator) comes up without manual
     intervention.
  3. Negative tests: wrong/expired cert rejected at every mTLS boundary; malformed VSS
     write rejected; OTA rollback actually rolls back.
  4. Write a one-page demo script: what you show, in what order, to make the "any sensor
     to any cloud and back, filtered at two levels" story land clearly.
- Exit criteria: cold-boot-to-working in a repeatable, timed sequence you can demo.

---

## 7. Requirements Summary (condensed, MoSCoW)

**Must have**
- ZCU sensor/actuator I/O over embedded C
- MQTT+mTLS ZCU↔HPC link
- KUKSA Databroker + custom VSS tree on both HPCs
- gRPC+mTLS HPC↔HPC bridge with subtree filtering
- gRPC/HTTPS+mTLS HPC↔Cloud (AWS and Azure respectively)
- Root/intermediate CA + per-device certs
- Docker isolation on HPC-2; Xen (Dom0+QNX DomU) on HPC-1

**Should have**
- Container-image OTA on both HPCs (A/B or tag-based)
- Digital Twin (cloud-side mirrored state)
- Predictive analytics on the QNX DomU
- HIL cold-boot integration test

**Could have**
- ZCU firmware OTA (separate bootloader project)
- Voice UI thin client
- Digital Key token flow
- SOME/IP as an additional HPC↔HPC service-discovery exercise

**Won't have (this POC)**
- Full Digital Twin simulation/physics model
- Production-grade safety certification (ASIL) of any kind
- Full UWB/BLE ranging-based digital key
- Direct ZCU-to-ZCU link (no hardware path exists)

---

## 8. Risk Register (carried forward)

| Risk | Impact | Mitigation |
|---|---|---|
| ~~STM32 Discovery lacks Ethernet PHY~~ **RESOLVED 2026-08-30** | both ZCU boards need external Ethernet | confirmed via datasheet: neither STM32F407G-DISC1 nor NUCLEO-F446RE has onboard Ethernet — W5500 SPI module required on **both**, no application-layer change needed |
| BBB 512MB RAM under container load | services OOM-killed | keep images minimal (Alpine), monitor memory in Phase 3, trim KUKSA/feeder footprint before adding more services |
| QNX SDP BSP support for RPi5 varies by release | Phase 2 stalls | verify BSP availability for your exact SDP version before committing the architecture to it; have a Yocto-on-RPi5-DomU fallback in your back pocket |
| KUKSA Databroker mTLS support unclear at your pinned version | weakens the security story | verify in Phase 5; use a TLS-terminating sidecar if native client-cert verification isn't there |
| Xen on RPi5 is a newer/less battle-tested combination than RPi4 | Phase 2 takes longer than expected | budget slack time here specifically; check current community BSP status before locking the plan to a firm date |
