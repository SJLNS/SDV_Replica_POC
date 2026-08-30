# SDV_Replica_POC — Execution Guide
## Tool installation → package installation → HW validation → HW bring-up → repo population

This is the "do this, in this order" companion to `SDV_Replica_POC_Architecture_Plan.md`.
That document has the *why*; this one has the *commands*. Read top to bottom the first
time — later, use it as a checklist.

---

## 0. Bill of Materials — what to buy beyond the 4 boards you have

You have the compute (RPi5, BBB, Discovery, Nucleo). Here's what closes the gap to a
working bench setup, roughly ordered by how soon you'll need it.

| Item | Why | Priority |
|---|---|---|
| 5x Ethernet patch cables (Cat5e/6, short) | ZCU1–HPC1, ZCU2–HPC2, HPC1–HPC2, + 2 spares for dev-workstation access | Must |
| 1x small unmanaged 5/8-port Ethernet switch | lets your dev workstation reach all 4 boards simultaneously for flashing/SSH/packet capture, without it sitting inline on a link you're trying to keep point-to-point-accurate | Must |
| USB-to-serial adapter (FTDI FT232 or CP2102), x2 | headless console access to the BBB and to STM32 boards' debug UART — you will need this the first time something doesn't boot | Must |
| microSD card, 32GB+, UHS-I A2, x1–2 | BBB root filesystem (4GB onboard eMMC will get tight fast once Docker images land); RPi5 boot media if not using NVMe | Must |
| RPi5 official active cooler | RPi5 throttles under sustained load; you *will* sustain load once Xen + QNX DomU + Docker are all running | Strongly recommended |
| RPi5 official USB-C power supply (5V/5A) | underpowering is the #1 cause of "random" RPi5 instability | Strongly recommended |
| NVMe SSD + PCIe HAT for RPi5 | optional, but meaningfully faster/more reliable than SD for a Xen Dom0 doing real I/O | Nice to have |
| W5500 SPI-Ethernet breakout module, **x2** (one per ZCU) | confirmed needed — neither STM32F407G-DISC1 nor NUCLEO-F446RE has onboard Ethernet (part numbers confirmed 2026-08-30) | Must |
| Breadboard, jumper wires, resistor kit | wiring sensors/actuators to the ZCU GPIO/ADC pins | Must |
| A few cheap sensors/actuators to start with: DHT22 (temp/humidity), a potentiometer (ADC test), 2x relay modules, a small DC motor or two, a handful of LEDs | Phase 1 bring-up needs *something* to read/drive before you trust the pipeline | Must |
| Multimeter | verifying wiring before you trust firmware — non-negotiable for the "bench-test in isolation" step in the plan | Must |
| USB hub (powered) | dev workstation will run out of ports fast between ST-Link, FTDI adapters, and Ethernet dongle | Nice to have |

Nucleo boards have an onboard ST-Link debugger; most Discovery boards do too — confirm
on your specific part number before assuming you need a separate probe.

---

## 1. Git repository creation

### 1.1 Create the remote

Pick GitHub or GitLab — both are fine, examples use GitHub via the `gh` CLI (install it
first: `sudo apt install gh` or see cli.github.com).

```bash
gh auth login
gh repo create SDV_Replica_POC --public --description "Personal SDV zonal-architecture POC: 2 ZCUs, 2 HPCs, dual-cloud" --clone
cd SDV_Replica_POC
```

If you'd rather do it by hand: create an empty repo on github.com, then locally:

```bash
git init SDV_Replica_POC && cd SDV_Replica_POC
git remote add origin git@github.com:<you>/SDV_Replica_POC.git
```

### 1.2 License

Since your core middleware dependency (KUKSA) is Apache-2.0, match it — avoids any
license-compatibility thinking later:

```bash
curl -o LICENSE https://www.apache.org/licenses/LICENSE-2.0.txt
```

### 1.3 `.gitignore`

```gitignore
# build artifacts
build/
*.o
*.elf
*.bin
*.hex
*.map

# Yocto
hpc2-bbb/yocto/build*/
hpc2-bbb/yocto/downloads/
hpc2-bbb/yocto/sstate-cache/
poky/

# Xen / QNX
hpc1-rpi5/xen/build*/
*.qnxbin

# Python
__pycache__/
*.pyc
.venv/

# secrets - never commit real key material
pki/certs/
pki/**/*.key
*.pem
!pki/scripts/**

# editors / OS
.vscode/
.idea/
.DS_Store
```

### 1.4 Branch strategy

Trunk-based is enough for a solo POC — don't over-engineer this part:

- `main` — always buildable, protected (require PR even solo, it forces you to read your
  own diffs)
- short-lived feature branches: `zcu1-firmware`, `hpc1-xen`, `hpc2-yocto`, `pki-setup`,
  `kuksa-integration`, etc. — one per phase from the architecture doc's Section 6

### 1.5 First commit — scaffold the folder structure

```bash
mkdir -p docs/diagrams pki/root-ca pki/intermediate-ca/zcu-ca pki/intermediate-ca/hpc-ca \
         pki/intermediate-ca/cloud-ca pki/scripts pki/certs \
         vss zcu/zcu1-discovery/src zcu/zcu1-discovery/inc zcu/zcu1-discovery/drivers zcu/zcu1-discovery/net \
         zcu/zcu2-nucleo/src zcu/zcu2-nucleo/inc zcu/zcu2-nucleo/drivers zcu/zcu2-nucleo/net \
         hpc1-rpi5/xen/dom0-config hpc1-rpi5/xen/domu-qnx-config \
         hpc1-rpi5/dom0-services/kuksa-databroker hpc1-rpi5/dom0-services/mqtt-feeder \
         hpc1-rpi5/dom0-services/hpc-bridge hpc1-rpi5/dom0-services/cloud-gateway \
         hpc1-rpi5/qnx-domu/predictive-analytics \
         hpc2-bbb/yocto/meta-sdvreplica \
         hpc2-bbb/containers/kuksa-databroker hpc2-bbb/containers/mqtt-feeder \
         hpc2-bbb/containers/hpc-bridge hpc2-bbb/containers/cloud-gateway \
         cloud/aws/iot-core cloud/aws/services cloud/azure/iot-hub cloud/azure/services \
         proto ota/hpc-ota ota/zcu-ota voice-ui digital-key test/integration test/hil

# drop a README stub in every leaf folder so git actually tracks the empty structure
find . -type d -not -path './.git*' -exec sh -c 'test -e "$1/README.md" || echo "# $(basename "$1")" > "$1/README.md"' _ {} \;

git add -A
git commit -m "chore: scaffold project structure"
git push -u origin main
```

---

## 2. Development workstation — tool & package installation

Assume Ubuntu 22.04/24.04 on the workstation (adjust package manager if you're on
something else). Run this once, up front.

```bash
sudo apt update && sudo apt upgrade -y

# --- core dev tools ---
sudo apt install -y git curl wget build-essential cmake ninja-build pkg-config \
    python3 python3-pip python3-venv gawk diffstat unzip texinfo \
    chrpath socat cpio zstd lz4 file locales

# --- ZCU (STM32) toolchain ---
sudo apt install -y gcc-arm-none-eabi gdb-multiarch openocd stlink-tools
# GUI IDE (optional but convenient for the first bring-up): download STM32CubeIDE
# from st.com directly (requires ST account, not apt-installable)

# --- Docker (for KUKSA, feeders, bridges - dev-machine prototyping before deploying to HPCs) ---
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out/in after this

# --- PKI tooling ---
sudo apt install -y openssl
# step-ca / step CLI (recommended once past the first openssl-only pass):
wget https://github.com/smallstep/cli/releases/latest/download/step-cli_amd64.deb
sudo dpkg -i step-cli_amd64.deb

# --- protobuf / gRPC tooling (for the shared .proto contracts) ---
sudo apt install -y protobuf-compiler
pip install --break-system-packages grpcio grpcio-tools

# --- KUKSA client (Python SDK, for smoke-testing the databroker) ---
pip install --break-system-packages kuksa-client

# --- MQTT tooling ---
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl disable --now mosquitto   # you only want the CLI tools on the workstation, not a running broker

# --- Yocto build dependencies (for building the BBB image) ---
sudo apt install -y gawk wget git diffstat unzip texinfo gcc build-essential chrpath \
    socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev python3-subunit mesa-common-dev \
    zstd liblz4-tool file locales libacl1

# --- Xen build dependencies (for building/patching Xen aarch64) ---
sudo apt install -y libssl-dev libncurses-dev bison flex libglib2.0-dev \
    libpixman-1-dev python3-dev uuid-dev

# --- QEMU (test firmware/kernels before touching real hardware - worth having) ---
sudo apt install -y qemu-system-arm qemu-system-aarch64
```

Verify the important ones before moving on:

```bash
arm-none-eabi-gcc --version
docker --version && docker run hello-world
protoc --version
step version
kuksa-client --help
```

---

## 3. Hardware validation — bench-test every board standalone, before any wiring together

Do this before Phase 1 of the architecture plan, not as part of it. The rule: **never
debug two unknowns at once.** If a board hasn't proven itself standalone, don't add it
to a multi-board chain.

### 3.1 STM32 Discovery / Nucleo (ZCU-1 / ZCU-2)

1. Connect via USB (ST-Link is onboard on Nucleo, and on most Discovery variants).
2. `openocd -f interface/stlink.cfg -f target/stm32f4x.cfg` (swap target file for your
   exact part) — confirm OpenOCD detects the chip ID.
3. Flash a bare "blink an LED" project first — this alone validates toolchain, debugger,
   and board power.
4. Confirm the onboard user button / LED works before touching your own wiring.
5. **Ethernet PHY question resolved (2026-08-30):** confirmed via datasheet — neither
   the STM32F407G-DISC1 (STM32F407VGT6) nor the NUCLEO-F446RE (STM32F446RET6, a
   Nucleo-64 board) has an onboard Ethernet PHY. Wire up a W5500 SPI-Ethernet module
   to both boards (see BOM, §0) before writing ZCU network code.
6. Bench-test each sensor/actuator you'll wire up, **in isolation, with a multimeter**,
   before connecting it to the board. Confirm voltage levels match the board's GPIO
   tolerance (3.3V logic — do not feed 5V sensor outputs directly into GPIO pins without
   level shifting).

### 3.2 Raspberry Pi 5 (HPC-1)

1. Flash stock Raspberry Pi OS (64-bit) first — just to confirm the board, PSU, and
   storage medium are all healthy before you touch Xen.
2. Boot, SSH in, confirm `uname -m` shows `aarch64`, confirm `vcgencmd measure_temp`
   under idle and light load (this is your baseline before adding Xen/QNX load).
3. Confirm Ethernet link and a DHCP lease from your switch.
4. Only after this succeeds cleanly, move to Phase 2 (Xen) from the architecture plan —
   don't build Xen on top of a board you haven't proven stable.

### 3.3 BeagleBone Black (HPC-2)

1. Boot the stock Debian image that ships on eMMC first (or flash latest from
   beagleboard.org if the onboard image is old).
2. Confirm serial console access via your USB-FTDI adapter on the debug UART header —
   you'll want this working *before* you need it for a failed-boot debug session, not
   during one.
3. Confirm Ethernet link/DHCP.
4. Check available eMMC space (`df -h`) — this is your early warning for the "512MB RAM
   / tight storage" risk already in the register.

---

## 4. Hardware bring-up — OS / hypervisor / container layer

This section gives the concrete commands behind Phases 2-3 of the architecture plan.

### 4.1 HPC-1: Xen on Raspberry Pi 5

```bash
# On the RPi5 itself (Debian/Ubuntu arm64), after the stock-boot validation above:
sudo apt update
sudo apt install -y xen-hypervisor-4.17-arm64 xen-utils-4.17

# Reboot into Xen - check /boot/firmware/config.txt or the equivalent bootloader entry
# gets a Xen kernel line added. Community images (e.g. the xen-troops RPi5 build) automate
# this step if the raw Debian-package route gives you trouble - check their repo linked
# in the risk register before spending too long hand-patching boot config.

# after reboot into Xen:
sudo xl list          # should show Domain-0
sudo xl info           # confirm CPU count visible to the hypervisor
```

Create the Dom0 vCPU pin and the QNX DomU config (`hpc1-rpi5/xen/domu-qnx-config/qnx.cfg`):

```
name = "qnx-domu"
kernel = "/path/to/qnx-ifs-image"
memory = 2048
vcpus = 3
vif = [ 'bridge=xenbr0' ]
```

```bash
sudo xl create hpc1-rpi5/xen/domu-qnx-config/qnx.cfg
sudo xl list          # confirm both Dom0 and qnx-domu are running
sudo xl console qnx-domu   # attach to the QNX console
```

Obtain the QNX SDP (Software Development Platform) non-commercial license from
blackberry.qnx.com, confirm the BSP you download explicitly lists RPi5 support before
building the IFS image for it — this is the risk flagged earlier, resolve it here, not
mid-Phase-2.

### 4.2 HPC-2: Yocto + Docker on BeagleBone Black

```bash
mkdir -p ~/yocto && cd ~/yocto
git clone git://git.yoctoproject.org/poky
cd poky
git checkout wrynose   # current LTS as of mid-2026 - verify at yoctoproject.org/releases
                        # before checking out; if meta-ti / meta-virtualization aren't
                        # yet updated for it, fall back to the scarthgap LTS branch instead

git clone git://git.yoctoproject.org/meta-ti ../meta-ti
git clone https://git.yoctoproject.org/meta-arm ../meta-arm
git clone git://git.openembedded.org/meta-openembedded ../meta-openembedded
git clone https://git.yoctoproject.org/meta-virtualization ../meta-virtualization

source oe-init-build-env

# add layers
bitbake-layers add-layer ../../meta-ti/meta-ti-bsp
bitbake-layers add-layer ../../meta-openembedded/meta-oe
bitbake-layers add-layer ../../meta-openembedded/meta-python
bitbake-layers add-layer ../../meta-openembedded/meta-networking
bitbake-layers add-layer ../../meta-virtualization

echo 'MACHINE = "beaglebone-yocto"' >> conf/local.conf
echo 'IMAGE_INSTALL:append = " docker docker-compose"' >> conf/local.conf

bitbake core-image-minimal
```

Flash the resulting image per the standard BeagleBone eMMC-flashing procedure (write to
SD, boot with the eMMC-flasher button held, let it flash, remove SD, reboot).

```bash
# on-device, once booted:
docker run hello-world
```

### 4.3 PKI bring-up (needed before either HPC talks to anything over the network)

```bash
cd pki

# Root CA (offline - do this on a machine that won't stay network-connected long-term
# if you want to take the exercise seriously; fine on your dev workstation for a POC)
openssl genrsa -out root-ca/root-ca.key 4096
openssl req -x509 -new -nodes -key root-ca/root-ca.key -sha256 -days 3650 \
  -out root-ca/root-ca.crt -subj "/CN=SDV_Replica_POC Root CA"

# Intermediate CAs (repeat for zcu-ca, hpc-ca, cloud-ca)
for ca in zcu-ca hpc-ca cloud-ca; do
  openssl genrsa -out intermediate-ca/$ca/$ca.key 4096
  openssl req -new -key intermediate-ca/$ca/$ca.key -out intermediate-ca/$ca/$ca.csr \
    -subj "/CN=SDV_Replica_POC $ca"
  openssl x509 -req -in intermediate-ca/$ca/$ca.csr -CA root-ca/root-ca.crt \
    -CAkey root-ca/root-ca.key -CAcreateserial -out intermediate-ca/$ca/$ca.crt -days 1825 -sha256
done
```

Leaf-cert issuance per device follows the same `req`/`x509 -req` pattern signed by the
relevant intermediate — script this into `pki/scripts/issue.sh` once you've done it
manually once and understand each step (don't script something you don't yet
understand — that's how POCs turn into unauditable messes).

---

## 5. Populating the repo with real content (Phase 5-8 starter material)

Once the OS/hypervisor layer boots on both HPCs and PKI is issuing certs, start filling
in the folders you scaffolded in Section 1.5 with actual working pieces — smallest first.

### 5.1 VSS extension (`vss/vss_custom.vspec`)

```yaml
Vehicle.SDVReplica.ZCU1.Temperature:
  type: sensor
  datatype: float
  unit: celsius
  description: Temperature reading from ZCU-1 branch sensor

Vehicle.SDVReplica.ZCU1.RelayA.IsOpen:
  type: actuator
  datatype: boolean
  description: Commanded state of relay A on ZCU-1 branch
```

Generate the JSON the databroker loads:

```bash
pip install --break-system-packages vss-tools
# NOTE: vss-tools' CLI changed to a unified `vspec` command with an `export`
# subcommand (checked directly against vss-tools 6.0.0) - the old `vspec2json`
# entry point some older tutorials reference no longer exists:
vspec export json -s vss/vss_custom.vspec -o vss/vss.json
# Your vss_custom.vspec is an overlay, not a full tree - for a real build you'll
# want the base COVESA VSS tree as the root and apply this as an overlay with -l:
#   vspec export json -s <path-to-covesa-vehicle_signal_specification>/spec/VehicleSignalSpecification.vspec \
#     -l vss/vss_custom.vspec -o vss/vss.json
```

### 5.2 KUKSA Databroker (`hpc1-rpi5/dom0-services/kuksa-databroker/docker-compose.yml`)

```yaml
services:
  databroker:
    image: ghcr.io/eclipse-kuksa/kuksa-databroker:main
    ports: ["55555:55555"]
    volumes:
      - ../../../vss:/vss:ro
      - ../../../pki/certs/hpc1:/certs:ro
    command: >
      --vss /vss/vss.json
      --tls-cert /certs/hpc1.crt
      --tls-private-key /certs/hpc1.key
```

Copy this pattern to `hpc2-bbb/containers/kuksa-databroker/` for HPC-2, pointing at its
own cert.

### 5.3 Proto contract (`proto/hpc_bridge.proto`)

```protobuf
syntax = "proto3";
package sdvreplica.hpcbridge.v1;

service HpcBridge {
  rpc StreamSignals(stream SignalUpdate) returns (stream SignalUpdate);
}

message SignalUpdate {
  string vss_path = 1;
  double numeric_value = 2;
  bool bool_value = 3;
  int64 timestamp_ms = 4;
}
```

### 5.4 MQTT feeder skeleton (`hpc1-rpi5/dom0-services/mqtt-feeder/feeder.py`)

```python
import paho.mqtt.client as mqtt
from kuksa_client.grpc import VSSClient, Datapoint

VSS_TOPIC_MAP = {
    "zcu1/sensor/temperature": "Vehicle.SDVReplica.ZCU1.Temperature",
}

def on_message(client, userdata, msg):
    vss_path = VSS_TOPIC_MAP.get(msg.topic)
    if not vss_path:
        return
    with VSSClient("localhost", 55555) as vss:
        vss.set_current_values({vss_path: Datapoint(float(msg.payload))})

mqttc = mqtt.Client()
mqttc.tls_set(ca_certs="/certs/ca.crt", certfile="/certs/feeder.crt", keyfile="/certs/feeder.key")
mqttc.on_message = on_message
mqttc.connect("mosquitto", 8883)
mqttc.subscribe("zcu1/sensor/#")
mqttc.loop_forever()
```

This is intentionally minimal — a starting skeleton, not production code. Add error
handling, reconnect logic, and the reverse (VSS actuation target -> MQTT publish) path
once this direction is proven working end to end.

### 5.5 README population

Every leaf folder got a one-line README stub in Section 1.5 — go back and write a real
paragraph in each as you build that piece, not before. A README written before the code
exists tends to describe the plan, not the thing; write it once you know what you
actually built.

---

## 6. Network / IP addressing plan

Not covered earlier and you'll need it the moment more than one board is on the switch
at once. Keep it simple and static — DHCP-for-everything on a 4-device POC just adds a
layer of "which IP did it get this time" debugging you don't need.

| Device | Static IP | Notes |
|---|---|---|
| Dev workstation | 192.168.50.10 | also runs `tcpdump`/Wireshark when you need to see a handshake fail |
| ZCU-1 (Discovery) | 192.168.50.21 | direct link or via switch to HPC-1 |
| ZCU-2 (Nucleo) | 192.168.50.22 | direct link or via switch to HPC-2 |
| HPC-1 Dom0 (RPi5) | 192.168.50.31 | external-facing interface |
| HPC-1 QNX DomU | 10.0.0.2 (internal Xen virtual bridge, not on the LAN) | talks to Dom0 only, Dom0 proxies anything further |
| HPC-2 (BBB) | 192.168.50.32 | |

Set these via static config on each device rather than DHCP reservations on the switch
(most unmanaged switches don't do DHCP at all) — one less piece of infrastructure to
depend on. Add hostnames to `/etc/hosts` on the workstation (`hpc1.local`, `hpc2.local`,
etc.) or run `avahi-daemon` on the HPCs for mDNS if you'd rather not hardcode IPs
everywhere.

---

## 7. Cloud account & CLI setup

### 7.1 AWS IoT Core (HPC-1 branch)

```bash
pip install --break-system-packages awscli
aws configure   # access key, secret, region

# Preferred: register your OWN cloud-ca as a trusted CA in IoT Core, instead of using
# AWS-generated certs — this keeps the whole system on the one PKI you built in Section 4.3
# rather than mixing two trust chains.
aws iot register-ca-certificate \
  --ca-certificate file://pki/intermediate-ca/cloud-ca/cloud-ca.crt \
  --verification-certificate file://pki/scripts/verification.pem \
  --set-as-active --allow-auto-registration

aws iot create-thing --thing-name hpc1-gateway

# issue HPC-1's cloud-facing leaf cert from your own cloud-ca (same pattern as Section 4.3),
# then register the resulting device cert against the Thing:
aws iot register-certificate \
  --certificate-pem file://pki/certs/hpc1-cloud.crt \
  --ca-certificate-pem file://pki/intermediate-ca/cloud-ca/cloud-ca.crt \
  --set-as-active

aws iot create-policy --policy-name SDVReplicaHPC1Policy --policy-document file://cloud/aws/iot-core/policy.json
aws iot attach-policy --policy-name SDVReplicaHPC1Policy --target <certificate-arn>
```

### 7.2 Azure IoT Hub (HPC-2 branch)

```bash
az login
az extension add --name azure-iot
az iot hub create --name sdvreplica-hub --resource-group sdvreplica-rg --sku F1

# Azure IoT Hub also supports X.509 CA-signed auth — upload your cloud-ca as a trusted
# root instead of Azure-generated certs, same reasoning as the AWS side:
az iot hub certificate create --hub-name sdvreplica-hub --name sdvreplica-cloud-ca \
  --path pki/intermediate-ca/cloud-ca/cloud-ca.crt

az iot hub device-identity create --hub-name sdvreplica-hub --device-id hpc2-gateway --auth-method x509_ca
```

Both cloud providers' free/lowest tiers (AWS IoT Core free tier, Azure IoT Hub F1 free
tier) are enough for this POC's message volume — no need to provision anything paid.

---

## 8. CI skeleton — sanity checks on every push

This won't (and can't) replace hardware-in-the-loop testing — GitHub-hosted runners
don't have your boards attached — but it catches broken builds and malformed configs
before you find out the hard way at the bench.

`.github/workflows/build.yml`:

```yaml
name: build-and-lint
on: [push, pull_request]

jobs:
  zcu-firmware:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ARM toolchain
        run: sudo apt-get update && sudo apt-get install -y gcc-arm-none-eabi cmake
      - name: Build ZCU-1 firmware
        run: cmake -S zcu/zcu1-discovery -B build-zcu1 && cmake --build build-zcu1
      - name: Build ZCU-2 firmware
        run: cmake -S zcu/zcu2-nucleo -B build-zcu2 && cmake --build build-zcu2

  compose-and-proto-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate docker-compose files
        run: |
          for f in hpc1-rpi5/dom0-services/*/docker-compose.yml hpc2-bbb/containers/*/docker-compose.yml; do
            [ -f "$f" ] && docker compose -f "$f" config >/dev/null
          done
      - name: Lint .proto contracts
        run: |
          sudo apt-get install -y protobuf-compiler
          mkdir -p /tmp/proto-out
          protoc --proto_path=proto --python_out=/tmp/proto-out proto/*.proto
```

---

## 9. Electrical safety — read this before wiring motors/relays/contactors

This got skipped earlier because it's not a software concern, but it's the one category
of mistake here that can hurt you or start a fire, so it goes in explicitly:

- **Check the rated voltage/current of every relay and contactor before wiring it.**
  Contactors in particular are often sized for motor-starting/higher-current loads —
  confirm what you actually have before assuming it's a benign low-voltage part.
- **If any load is mains voltage, treat that wiring as a separate, higher-stakes task**
  from the rest of the bench setup — proper isolation, fusing, and no live-wire work.
  If you're not already confident with mains wiring, keep this POC's actuators to
  low-voltage DC loads (motors, DC relay coils) and simulate anything mains-adjacent
  with an LED + note rather than the real thing.
- **Flyback diodes on every inductive load** (motor windings, relay coils) — without one,
  switching off an inductive load can spike voltage high enough to damage your GPIO or
  driver transistor.
- **Opto-isolate relay/motor driver circuits from the MCU GPIO** where practical — keeps
  a wiring mistake on the actuator side from taking out the STM32.
- **Never leave an energized actuator unattended** during early bring-up, before you
  trust the firmware's fault behavior.

---

## 10. Version pinning reference

Scattered across both documents — here's the one table to check before you install
anything, so you're not hunting through prior sections mid-build.

| Component | Version to use | Note |
|---|---|---|
| Xen | 4.17-arm64 (Debian package) or current xen-troops RPi5 build | verify current RPi5 community-build status before committing |
| Yocto | 6.0 "Wrynose" (LTS) | fall back to 5.0 "Scarthgap" (LTS) if `meta-ti`/`meta-virtualization` lag the new release |
| KUKSA Databroker | pin to a tagged release once you're past first bring-up | don't ship long-term on the `:main` tag — fine for the very first smoke test only |
| Docker Engine | latest stable from get.docker.com | |
| QNX SDP | confirm exact release has an RPi5 BSP before downloading | this is the biggest open unknown in the whole plan — resolve first |
| protobuf / grpc-tools | latest from pip/apt | no known compatibility traps at time of writing |
| step-cli | latest GitHub release | |

---

## 11. Backup / recovery practice

Cheap insurance against re-doing hours of bring-up work after a corrupted SD card or a
bad config push:

- Once a board reaches a "known good" state (boots clean, passes its Section 3
  validation), image the boot media: `sudo dd if=/dev/sdX of=golden-hpc1-$(date +%F).img bs=4M status=progress`
  — store it off-device, not just on the same disk you're imaging.
- Tag git commits at every exit-criteria milestone from the architecture plan's Phase
  list (`git tag phase2-xen-boots-clean`) so you can always check out a known-working
  point rather than bisecting a long history under time pressure.

---

## 12. Rough time budget (part-time, evenings/weekends)

Not a commitment, just a planning anchor so you can sequence realistically:

| Phase | Estimate | Risk |
|---|---|---|
| Workstation setup + BOM arrival | 2-3 days | low |
| HW validation (Section 3) | 1 day | low |
| Xen bring-up on RPi5 | 3-7 days | **high** — least mature path in the whole plan |
| QNX DomU under Xen | 2-4 days | high, gated on BSP availability |
| Yocto + Docker on BBB | 2-4 days | medium |
| PKI setup | 1 day | low |
| KUKSA + VSS + feeders | 2-3 days | low |
| ZCU firmware (MQTT+mTLS) | 3-5 days | medium |
| HPC-HPC gRPC bridge | 1-2 days | low |
| Cloud integration (both) | 3-5 days | low-medium |
| OTA (SOTA) | 3-5 days | medium |
| Stretch features (Digital Twin, Voice UI, Digital Key, predictive analytics) | open-ended | low, by design |

Total core path (through Phase 8/cloud integration): roughly **4-6 weeks** part-time,
with the Xen/QNX step being the one most likely to blow the estimate — budget slack
there specifically, not evenly across every phase.

---

## 13. Execution checklist (tick these off in order)

- [ ] BOM ordered (Section 0)
- [ ] Git repo created, scaffolded, pushed (Section 1)
- [ ] Workstation tools installed and verified (Section 2)
- [ ] All 4 boards bench-validated standalone (Section 3)
- [ ] STM32 Ethernet question resolved (Section 3.1 step 5)
- [ ] Xen running on RPi5, Dom0 confirmed (Section 4.1)
- [ ] QNX DomU booting under Xen (Section 4.1)
- [ ] Yocto + Docker running on BBB (Section 4.2)
- [ ] PKI root/intermediate CAs generated (Section 4.3)
- [ ] First leaf certs issued and a bare openssl mTLS handshake proven (architecture
      plan Phase 4)
- [ ] VSS extension written, KUKSA Databroker running on both HPCs (Section 5.1-5.2)
- [ ] MQTT feeder skeleton passing one real sensor value end to end (Section 5.4)
- [ ] Proceed to architecture plan Phase 6 onward (ZCU<->HPC MQTT integration through
      cloud connectivity)
- [ ] Static IP plan applied to all boards + workstation (Section 6)
- [ ] AWS IoT Core Thing + Azure IoT Hub device identity provisioned, both using your
      own cloud-ca rather than provider-generated certs (Section 7)
- [ ] CI workflow added and passing on a clean push (Section 8)
- [ ] Electrical safety pass done on every relay/contactor/motor wiring before power-on
      (Section 9)
- [ ] Versions checked against the pinning table, QNX BSP availability confirmed first
      (Section 10)
- [ ] First golden-image backup taken after each board's first "known good" boot
      (Section 11)
- [ ] Copy of both this guide and the architecture plan committed into `docs/` in the
      repo, and the A3 diagram files placed in `docs/diagrams/`
