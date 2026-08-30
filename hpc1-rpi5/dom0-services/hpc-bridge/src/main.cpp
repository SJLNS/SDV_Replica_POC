// HPC-1 (Raspberry Pi 5, Dom0) - hpc-bridge
//
// gRPC bridge to HPC-2 over the Ethernet backbone (mTLS 1.3, VSS subtree filtering).
// See proto/hpc_bridge.proto for the shared contract and the architecture doc's
// "HPC-level filtering" section for what this service is responsible for enforcing.
//
// This skeleton proves the C++ toolchain + CMake build path work cleanly, matching
// the same "prove the build first, layer in real logic next" pattern used for the
// ZCU firmware skeletons (zcu/zcu1-discovery, zcu/zcu2-nucleo). Do not add gRPC/
// protobuf logic until this compiles and links on your actual target machine.
//
// TODO once libgrpc++-dev / libprotobuf-dev are available on the build machine:
//   1. Generate proto/hpc_bridge.pb.h and proto/hpc_bridge.grpc.pb.h from
//      proto/hpc_bridge.proto (protoc --grpc_out / --cpp_out).
//   2. Implement HpcBridge::StreamSignals as a bidirectional gRPC stream.
//   3. Load TLS 1.3 mutual-auth credentials from pki/certs/hpc1/ instead of
//      grpc::InsecureServerCredentials() - see architecture doc PKI section.
//   4. Apply the VSS subtree filter here before forwarding anything to HPC-2 -
//      this file IS the HPC-level filtering boundary described in the architecture doc.
//   5. Connect to the local KUKSA Databroker (localhost:55555) to source signals.

#include <iostream>
#include <string>

int main() {
    std::cout << "[hpc-bridge/hpc1] HPC-1 <-> HPC-2 gRPC bridge skeleton starting..." << std::endl;
    std::cout << "[hpc-bridge/hpc1] TODO: wire up grpc++ server, VSS subtree filter, mTLS 1.3" << std::endl;
    return 0;
}
