// HPC-2 (BeagleBone Black, Yocto+Docker) - hpc-bridge
//
// gRPC bridge to HPC-1 over the Ethernet backbone (mTLS 1.3, VSS subtree filtering).
// Mirror of hpc1-rpi5/dom0-services/hpc-bridge, running the other direction.
// See proto/hpc_bridge.proto for the shared contract.
//
// This skeleton proves the C++ toolchain + CMake build path work cleanly on this
// service too - prove the build first, layer in real logic next.
//
// TODO once libgrpc++-dev / libprotobuf-dev are available on the build machine:
//   1. Generate proto/hpc_bridge.pb.h and proto/hpc_bridge.grpc.pb.h from
//      proto/hpc_bridge.proto.
//   2. Implement HpcBridge::StreamSignals as a bidirectional gRPC stream.
//   3. Load TLS 1.3 mutual-auth credentials from pki/certs/hpc2/ instead of
//      grpc::InsecureServerCredentials().
//   4. Apply the VSS subtree filter here before forwarding anything to HPC-1.
//   5. Connect to the local KUKSA Databroker (localhost:55555) to source signals.
//
// NOTE: the BBB is a single-core, 512MB-RAM board with no hypervisor (see
// architecture doc hardware corrections) - keep this service's memory footprint
// small once real gRPC logic is added; watch for the RAM risk already flagged
// in the architecture doc's risk register.

#include <iostream>
#include <string>

int main() {
    std::cout << "[hpc-bridge/hpc2] HPC-2 <-> HPC-1 gRPC bridge skeleton starting..." << std::endl;
    std::cout << "[hpc-bridge/hpc2] TODO: wire up grpc++ server, VSS subtree filter, mTLS 1.3" << std::endl;
    return 0;
}
