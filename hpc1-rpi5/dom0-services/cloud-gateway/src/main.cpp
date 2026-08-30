// HPC-1 (Raspberry Pi 5, Dom0) - cloud-gateway
//
// gRPC/HTTPS bridge from HPC-1's local VSS tree to AWS IoT Core (mTLS 1.3).
// See the architecture doc's "HPC <-> Cloud" protocol row and Execution Guide
// Section 7.1 (AWS IoT Core setup, using the project's own cloud-ca).
//
// This skeleton proves the C++ toolchain + CMake build path work cleanly, matching
// the same pattern used across every other module in this repo - prove the build
// first, layer in real logic next.
//
// TODO once libgrpc++-dev / libprotobuf-dev / an AWS IoT SDK are available:
//   1. Connect to the local KUKSA Databroker (localhost:55555) to source the
//      filtered VSS subtree that's allowed to leave this HPC.
//   2. Publish to AWS IoT Core over mTLS 1.3 using the hpc1-cloud leaf cert
//      issued from pki/intermediate-ca/cloud-ca (see Execution Guide Section 7.1).
//   3. Subscribe to AWS-side command topics and write actuation targets back into
//      the local VSS tree.

#include <iostream>
#include <string>

int main() {
    std::cout << "[cloud-gateway/hpc1] HPC-1 -> AWS IoT Core gateway skeleton starting..." << std::endl;
    std::cout << "[cloud-gateway/hpc1] TODO: wire up grpc++/AWS IoT client, mTLS 1.3" << std::endl;
    return 0;
}
