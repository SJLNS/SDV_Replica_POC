// HPC-2 (BeagleBone Black, Yocto+Docker) - cloud-gateway
//
// gRPC/HTTPS bridge from HPC-2's local VSS tree to Azure IoT Hub (mTLS 1.3).
// See Execution Guide Section 7.2 (Azure IoT Hub setup, using the project's own cloud-ca).
//
// This skeleton proves the C++ toolchain + CMake build path work cleanly - prove
// the build first, layer in real logic next.
//
// TODO once libgrpc++-dev / libprotobuf-dev / an Azure IoT SDK are available:
//   1. Connect to the local KUKSA Databroker (localhost:55555) to source the
//      filtered VSS subtree that's allowed to leave this HPC.
//   2. Publish to Azure IoT Hub over mTLS 1.3 using the hpc2-cloud leaf cert
//      issued from pki/intermediate-ca/cloud-ca (see Execution Guide Section 7.2).
//   3. Subscribe to Azure-side command topics and write actuation targets back
//      into the local VSS tree.
//
// NOTE: keep this service's memory footprint small - see the BBB RAM risk in the
// architecture doc's risk register.

#include <iostream>
#include <string>

int main() {
    std::cout << "[cloud-gateway/hpc2] HPC-2 -> Azure IoT Hub gateway skeleton starting..." << std::endl;
    std::cout << "[cloud-gateway/hpc2] TODO: wire up grpc++/Azure IoT client, mTLS 1.3" << std::endl;
    return 0;
}
