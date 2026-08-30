cmake_minimum_required(VERSION 3.20)

# Target MCU: STM32F407VGT6 (STM32F407G-DISC1 Discovery board) - confirmed
# part number. Cortex-M4F core (has hardware FPU, currently unused - see
# CPU_FLAGS below for the optional hardware-FPU upgrade path).

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

project(zcu1_discovery C ASM)

set(CPU_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=soft")
# Optional upgrade once real float-heavy sensor math is added: this chip has
# a hardware FPU. Switch to "-mfloat-abi=hard -mfpu=fpv4-sp-d16" for real
# performance - requires every object file in the link to agree on this
# setting, so change it here only, not per-file.
set(CMAKE_C_FLAGS "${CPU_FLAGS} -Wall -Wextra -ffreestanding -O0 -g")
set(CMAKE_ASM_FLAGS "${CPU_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS
    "${CPU_FLAGS} -T${CMAKE_SOURCE_DIR}/linker/STM32F407VG_FLASH.ld -nostdlib -Wl,--gc-sections -Wl,-Map=zcu1_discovery.map")

add_executable(zcu1_discovery.elf
    src/startup.s
    src/main.c
)

target_include_directories(zcu1_discovery.elf PRIVATE inc)

add_custom_command(TARGET zcu1_discovery.elf POST_BUILD
    COMMAND arm-none-eabi-size zcu1_discovery.elf
    COMMAND arm-none-eabi-objcopy -O binary zcu1_discovery.elf zcu1_discovery.bin
)
