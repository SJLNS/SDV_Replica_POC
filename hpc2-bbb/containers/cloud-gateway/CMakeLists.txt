cmake_minimum_required(VERSION 3.16)
project(cloud_gateway_hpc2 CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

add_executable(cloud_gateway src/main.cpp)

# --- gRPC / protobuf integration - enable once dev packages are installed ---
# Install on Debian/Ubuntu (dev workstation or HPC-1 Dom0 itself):
#   sudo apt install -y libgrpc++-dev libprotobuf-dev protobuf-compiler-grpc
#
# Then uncomment:
# find_package(Protobuf REQUIRED)
# find_package(gRPC REQUIRED)
# get_filename_component(PROTO_FILE "${CMAKE_SOURCE_DIR}/../../../../proto/cloud_gateway.proto" ABSOLUTE)
# protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ${PROTO_FILE})
# target_sources(cloud_gateway PRIVATE ${PROTO_SRCS})
# target_include_directories(cloud_gateway PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
# target_link_libraries(cloud_gateway PRIVATE protobuf::libprotobuf gRPC::grpc++)
