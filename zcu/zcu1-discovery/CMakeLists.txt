###############################################################################
# @file        CMakeLists.txt
# @brief       CMake build configuration for ZCU-1 STM32 Discovery firmware.
#
# @author      Chittaranjan Baral
# @date        20-Sep-2026
# @version     1.0.0
#
# @copyright   Copyright (c) 2026 CRB. All rights reserved.
#
# @details
# This file defines the cross-compilation, compiler, CPU configuration,
# linker configuration, source files, include paths, and post-build
# generation steps required to build the ZCU-1 STM32 Discovery firmware.
#
# The current configuration targets the STM32F407VGT6 device used on the
# STM32F407G-DISC1 Discovery board.
#
# Target architecture:
#   - MCU       : STM32F407VGT6
#   - Core      : ARM Cortex-M4F
#   - FPU       : Hardware FPU available
#   - Toolchain : GNU Arm Embedded Toolchain
#   - Compiler   : arm-none-eabi-gcc
#   - Build      : Freestanding bare-metal firmware
#
# @module       ZCU
# @component    ZCU-1
# @platform     STM32F407G-DISC1
# @project      ENERGY_ZONE_SDV
#
# @build
#   Toolchain:
#       arm-none-eabi-gcc
#       arm-none-eabi-objcopy
#       arm-none-eabi-size
#
#   Output:
#       zcu1_discovery.elf
#       zcu1_discovery.bin
#       zcu1_discovery.map
#
# @bringup
#   1. Configure CMake.
#   2. Build the firmware.
#   3. Confirm ELF generation.
#   4. Confirm binary size using arm-none-eabi-size.
#   5. Confirm BIN generation using arm-none-eabi-objcopy.
#   6. Flash the generated BIN/ELF to the STM32 Discovery board.
#   7. Confirm firmware execution.
#   8. Add STM32 startup/HAL/MCAL functionality incrementally.
#
# @history
# ------------------------------------------------------------------------------
# Version     Date            Author                  Description
# ------------------------------------------------------------------------------
# 1.0.0       20-Sep-2026    Chittaranjan Baral       Initial version
# 1.1.0       20-Sep-2026    Chittaranjan Baral       Added mcal/gpio_driver.c
#                                                      to the zcu1-discovery
#                                                      build.
# ------------------------------------------------------------------------------
###############################################################################


###############################################################################
#                           CMAKE CONFIGURATION                               #
###############################################################################

cmake_minimum_required(VERSION 3.20)


###############################################################################
#                           TARGET MCU INFORMATION                             #
###############################################################################

# Target MCU:
#   STM32F407VGT6
#
# Target development board:
#   STM32F407G-DISC1 Discovery Board
#
# CPU:
#   ARM Cortex-M4F
#
# The Cortex-M4F contains a hardware floating-point unit (FPU).
# The current project intentionally uses software floating-point ABI
# until floating-point intensive sensor/application processing is introduced.


###############################################################################
#                           CROSS-COMPILER SETUP                              #
###############################################################################

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)

# Prevent CMake from attempting to execute target binaries during
# the compiler/toolchain detection stage.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)


###############################################################################
#                              PROJECT SETUP                                  #
###############################################################################

project(zcu1_discovery C ASM)


###############################################################################
#                             CPU CONFIGURATION                               #
###############################################################################

# Cortex-M4 CPU configuration.
#
# -mcpu=cortex-m4
#     Selects the ARM Cortex-M4 instruction set and architecture.
#
# -mthumb
#     Generates Thumb instruction set code.
#
# -mfloat-abi=soft
#     Uses software floating-point calling conventions.
#
# NOTE:
# The STM32F407 contains a hardware FPU. When real floating-point intensive
# processing is introduced, this can be upgraded to:
#
#     -mfloat-abi=hard -mfpu=fpv4-sp-d16
#
# IMPORTANT:
# Every object file participating in the final link must use a compatible
# floating-point ABI. Therefore, this configuration should be changed
# centrally here rather than on individual source files.

set(CPU_FLAGS
    "-mcpu=cortex-m4 -mthumb -mfloat-abi=soft"
)


###############################################################################
#                           COMPILER FLAGS                                    #
###############################################################################

set(CMAKE_C_FLAGS
    "${CPU_FLAGS} -Wall -Wextra -ffreestanding -O0 -g"
)

set(CMAKE_ASM_FLAGS
    "${CPU_FLAGS}"
)


###############################################################################
#                            LINKER CONFIGURATION                             #
###############################################################################

# STM32F407VG FLASH linker script.
#
# -T
#     Specifies the linker script defining the MCU memory layout.
#
# -nostdlib
#     Do not automatically link the standard system libraries.
#
# --gc-sections
#     Removes unused sections from the final image.
#
# -Map
#     Generates a linker map file for memory/link analysis.

set(CMAKE_EXE_LINKER_FLAGS
    "${CPU_FLAGS} -T${CMAKE_SOURCE_DIR}/linker/STM32F407VG_FLASH.ld -nostdlib -Wl,--gc-sections -Wl,-Map=zcu1_discovery.map"
)

###############################################################################
#                             SOURCE FILES                                    #
###############################################################################

add_executable(zcu1_discovery.elf

    # Startup code
    src/startup.s

    # Application entry point
    src/main.c

    # MCU abstraction / low-level drivers
    src/mcal/rcc_driver.c
	src/mcal/gpio_driver.c
)


###############################################################################
#                           INCLUDE DIRECTORIES                               #
###############################################################################

target_include_directories(
    zcu1_discovery.elf
    PRIVATE
        inc
)


###############################################################################
#                              POST BUILD                                     #
###############################################################################

# After successful ELF generation:
#
# 1. Display code/data memory usage.
# 2. Convert ELF into raw binary image.
#
# Generated files:
#
#   zcu1_discovery.elf
#   zcu1_discovery.bin
#   zcu1_discovery.map

add_custom_command(
    TARGET zcu1_discovery.elf
    POST_BUILD

    COMMAND arm-none-eabi-size
            zcu1_discovery.elf

    COMMAND arm-none-eabi-objcopy
            -O binary
            zcu1_discovery.elf
            zcu1_discovery.bin
)