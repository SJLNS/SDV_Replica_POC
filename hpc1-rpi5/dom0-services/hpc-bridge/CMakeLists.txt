cmake_minimum_required(VERSION 3.16)
project(hpc_bridge_hpc1 CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

add_executable(hpc_bridge src/main.cpp)

# --- gRPC / protobuf integration - enable once dev packages are installed ---
# Install on Debian/Ubuntu (dev workstation or HPC-1 Dom0 itself):
#   sudo apt install -y libgrpc++-dev libprotobuf-dev protobuf-compiler-grpc
#
# Then uncomment:
# find_package(Protobuf REQUIRED)
# find_package(gRPC REQUIRED)
# get_filename_component(PROTO_FILE "${CMAKE_SOURCE_DIR}/../../../../proto/hpc_bridge.proto" ABSOLUTE)
# protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILE})
# target_sources(hpc_bridge PRIVATE ${PROTO_SRCS})
# target_include_directories(hpc_bridge PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
# target_link_libraries(hpc_bridge PRIVATE protobuf::libprotobuf gRPC::grpc++)
