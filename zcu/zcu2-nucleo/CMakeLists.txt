cmake_minimum_required(VERSION 3.20)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

project(zcu2_nucleo C ASM)

set(CPU_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=soft")
set(CMAKE_C_FLAGS "${CPU_FLAGS} -Wall -Wextra -ffreestanding -O0 -g")
set(CMAKE_ASM_FLAGS "${CPU_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS
    "${CPU_FLAGS} -T${CMAKE_SOURCE_DIR}/linker/STM32_GENERIC.ld -nostdlib -Wl,--gc-sections -Wl,-Map=zcu2_nucleo.map")

add_executable(zcu2_nucleo.elf
    src/startup.s
    src/main.c
)

target_include_directories(zcu2_nucleo.elf PRIVATE inc)

add_custom_command(TARGET zcu2_nucleo.elf POST_BUILD
    COMMAND arm-none-eabi-size zcu2_nucleo.elf
    COMMAND arm-none-eabi-objcopy -O binary zcu2_nucleo.elf zcu2_nucleo.bin
)
