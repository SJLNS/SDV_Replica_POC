#!/usr/bin/env bash

###############################################################################
# @file        buildenv.sh
# @brief       Build wrapper for ZCU firmware targets.
#
# @author      Chittaranjan Baral
# @date        20-Sep-2026
# @version     1.2.0
#
# @copyright   Copyright (c) 2026 CRB. All rights reserved.
#
# @details
# This script provides a controlled build wrapper for ZCU firmware targets.
#
# Unlike a plain `cmake --build`, this script explicitly separates and
# preserves intermediate build artifacts, including:
#
#   - Preprocessed C source files (.i)
#   - Generated assembly files (.s)
#   - Object files (.o)
#   - Executable ELF files (.elf)
#   - Binary firmware images (.bin)
#   - Linker map files (.map)
#   - Timestamped build logs (.log)
#
# Each build operation is recorded as a numbered step in the build log.
# The exact command executed for each step is also recorded.
#
# If any build step fails:
#   - The build stops immediately.
#   - A prominent BUILD FAILED banner is printed.
#   - The failed step and return code are reported.
#   - The corresponding build log is identified.
#
# @module       ZCU
# @component    Build Infrastructure
# @platform     STM32
# @project      ENERGY_ZONE_SDV
#
# @targets
#   zcu1-discovery
#       STM32F407G-DISC1 Discovery Board
#       STM32F407VGT6
#       ARM Cortex-M4F
#
#   zcu2-nucleo
#       STM32F446RE Nucleo Board
#       STM32F446RE
#       ARM Cortex-M4F
#
# @toolchain
#   arm-none-eabi-gcc
#   arm-none-eabi-objcopy
#   arm-none-eabi-size
#
# @usage
#   Run from Git Bash from the repository root.
#
#   ./scripts/buildenv.sh <target> [clean]
#
#   Supported targets:
#       zcu1-discovery
#       zcu2-nucleo
#       all
#
#   Optional:
#       clean
#
# @examples
#   ./scripts/buildenv.sh zcu1-discovery
#   ./scripts/buildenv.sh zcu1-discovery clean
#   ./scripts/buildenv.sh zcu2-nucleo
#   ./scripts/buildenv.sh all
#   ./scripts/buildenv.sh all clean
#
# @output
#   build-output/
#       <target>/
#           preprocessed/
#           asm/
#           obj/
#           elf/
#           bin/
#           map/
#           logs/
#
# @bringup
#   1. Validate the ARM GNU toolchain.
#   2. Preprocess the application source.
#   3. Generate application assembly.
#   4. Compile application source into object code.
#   5. Assemble startup code.
#   6. Select the target-specific linker script.
#   7. Link the firmware into an ELF image.
#   8. Generate the binary firmware image.
#   9. Generate the firmware size report.
#  10. Review the linker MAP file when memory analysis is required.
#
# @history
# ------------------------------------------------------------------------------
# Version     Date            Author                  Description
# ------------------------------------------------------------------------------
# 1.0.0       20-Sep-2026    Chittaranjan Baral       Initial version
# 1.1.0       20-Sep-2026    Chittaranjan Baral       Added mcal/rcc_driver.c
#                                                      to the zcu1-discovery
#                                                      build (RCC clock-enable
#                                                      driver).
# 1.2.0       20-Sep-2026    Chittaranjan Baral       Added mcal/gpio_driver.c
#                                                      to the zcu1-discovery
#                                                      build (GPIO mode/output
#                                                      driver).
# ------------------------------------------------------------------------------
###############################################################################


###############################################################################
#                            SHELL CONFIGURATION                              #
###############################################################################

# Do not use `set -e` because this script explicitly handles and reports
# failures for every build step.
#
# -u : Treat unset variables as errors.
# -o pipefail : A pipeline fails if any command within the pipeline fails.

set -uo pipefail


###############################################################################
#                             INPUT PARAMETERS                                #
###############################################################################

TARGET="${1:-}"
CLEAN="${2:-}"


###############################################################################
#                           REPOSITORY CONFIGURATION                          #
###############################################################################

# Resolve the repository root from the location of this script rather than
# relying on the current working directory.
#
# This allows the script to be invoked from the repository root as intended
# while still providing a deterministic repository path internally.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


###############################################################################
#                              TOOLCHAIN                                      #
###############################################################################

CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
SIZE=arm-none-eabi-size


###############################################################################
#                            CPU CONFIGURATION                                #
###############################################################################

# Common CPU configuration for the current Cortex-M4 based ZCU targets.
#
# -mcpu=cortex-m4
#     Target ARM Cortex-M4 architecture.
#
# -mthumb
#     Generate Thumb instructions.
#
# -mfloat-abi=soft
#     Use software floating-point ABI.
#
# NOTE:
# Both current targets use Cortex-M4 based MCUs. The floating-point ABI
# should remain consistent across all object files participating in a link.

CPU_FLAGS="-mcpu=cortex-m4 -mthumb -mfloat-abi=soft"


###############################################################################
#                           COMPILER CONFIGURATION                            #
###############################################################################

CFLAGS="$CPU_FLAGS -Wall -Wextra -ffreestanding -O0 -g"


###############################################################################
#                              TERMINAL COLORS                               #
###############################################################################

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'


###############################################################################
#                              BUILD STATE                                    #
###############################################################################

STEP_NUM=0
LOGFILE=""


###############################################################################
#                              USAGE FUNCTION                                 #
###############################################################################

usage()
{
    echo "Usage: $0 <zcu1-discovery|zcu2-nucleo|all> [clean]"
    exit 1
}


###############################################################################
#                         BUILD FAILURE HANDLING                              #
###############################################################################

banner_error()
{
    local msg="$1"
    local border

    border=$(printf '%.0s#' $(seq 1 70))

    {
        echo ""
        echo "$border"
        echo "###  BUILD FAILED"
        echo "###  $msg"
        echo "$border"
        echo ""
    } >> "$LOGFILE"

    echo ""
    echo "${RED}${BOLD}${border}${RESET}"
    echo "${RED}${BOLD}###  BUILD FAILED${RESET}"
    echo "${RED}${BOLD}###  $msg${RESET}"
    echo "${RED}${BOLD}${border}${RESET}"
    echo ""
}


###############################################################################
#                              BUILD LOGGING                                  #
###############################################################################

log_step()
{
    STEP_NUM=$((STEP_NUM + 1))

    local desc="$1"

    {
        echo ""
        echo "[$STEP_NUM] $(date '+%Y-%m-%d %H:%M:%S') - $desc"
    } >> "$LOGFILE"
}


###############################################################################
#                         LOGGED COMMAND EXECUTION                            #
###############################################################################

run_logged()
{
    local desc="$1"
    shift

    log_step "$desc"

    echo "CMD: $*" >> "$LOGFILE"

    if "$@" >> "$LOGFILE" 2>&1; then

        echo "  ${GREEN}OK${RESET}  $desc"

        return 0

    else

        local rc=$?

        banner_error "$desc FAILED (exit $rc) - see $LOGFILE"

        return "$rc"
    fi
}


###############################################################################
#                             TARGET BUILD                                    #
###############################################################################

build_target()
{
    local target="$1"

    local src_dir="$REPO_ROOT/zcu/$target"
    local out_dir="$REPO_ROOT/build-output/$target"

    ###########################################################################
    #                         TARGET VALIDATION                               #
    ###########################################################################

    if [ ! -d "$src_dir" ]; then

        echo "${RED}No such target: $target (expected $src_dir)${RESET}"

        return 1
    fi


    ###########################################################################
    #                             CLEAN BUILD                                 #
    ###########################################################################

    if [ "$CLEAN" = "clean" ]; then

        rm -rf "$out_dir"
    fi


    ###########################################################################
    #                         OUTPUT DIRECTORY SETUP                          #
    ###########################################################################

    mkdir -p \
        "$out_dir/preprocessed" \
        "$out_dir/asm" \
        "$out_dir/obj" \
        "$out_dir/elf" \
        "$out_dir/bin" \
        "$out_dir/map" \
        "$out_dir/logs"


    ###########################################################################
    #                              BUILD LOG                                   #
    ###########################################################################

    LOGFILE="$out_dir/logs/build_$(date '+%Y%m%d_%H%M%S').log"

    : > "$LOGFILE"

    STEP_NUM=0

    echo "${BOLD}=== Building $target ===${RESET}"
    echo "Log file: $LOGFILE"

    echo "=== Building $target - $(date) ===" >> "$LOGFILE"


    ###########################################################################
    #                         OBJECT FILE COLLECTION                           #
    ###########################################################################

    local objs=()
    local base
    local src_rel


    ###########################################################################
    #                        APPLICATION SOURCE: main.c                        #
    ###########################################################################

    base=main

    # -------------------------------------------------------------------------
    # Preprocess C source
    # -------------------------------------------------------------------------

    run_logged "Preprocess $base.c" \
        "$CC" $CFLAGS \
        -I"$src_dir/inc" \
        -E "$src_dir/src/$base.c" \
        -o "$out_dir/preprocessed/$base.i" \
        || return 1


    # -------------------------------------------------------------------------
    # Generate assembly
    # -------------------------------------------------------------------------

    run_logged "Compile $base.c -> assembly" \
        "$CC" $CFLAGS \
        -I"$src_dir/inc" \
        -S "$src_dir/src/$base.c" \
        -o "$out_dir/asm/$base.s" \
        || return 1


    # -------------------------------------------------------------------------
    # Generate object file
    # -------------------------------------------------------------------------

    run_logged "Compile $base.c -> object" \
        "$CC" $CFLAGS \
        -I"$src_dir/inc" \
        -c "$src_dir/src/$base.c" \
        -o "$out_dir/obj/$base.o" \
        || return 1

    objs+=("$out_dir/obj/$base.o")


    ###########################################################################
    #                 APPLICATION SOURCE: mcal/rcc_driver.c                    #
    ###########################################################################

    # NOTE: this file lives in a subfolder (src/mcal/), unlike main.c which
    # sits directly in src/. "base" still names this file's own output
    # artifacts (rcc_driver.i / rcc_driver.s / rcc_driver.o), kept distinct
    # from main's; "src_rel" separately carries the real path to the source
    # file relative to src/.
    #
    # Only zcu1-discovery has this file today (ZCU-2 uses Zephyr's own build
    # system instead of this script). If zcu2-nucleo ever grows an equivalent
    # driver, gate this block on "if [ "$target" = "zcu1-discovery" ]" rather
    # than assuming both targets share it.

    if [ "$target" = "zcu1-discovery" ]; then

        base=rcc_driver
        src_rel="mcal/rcc_driver.c"

        # ---------------------------------------------------------------------
        # Preprocess C source
        # ---------------------------------------------------------------------

        run_logged "Preprocess $base.c" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -E "$src_dir/src/$src_rel" \
            -o "$out_dir/preprocessed/$base.i" \
            || return 1


        # ---------------------------------------------------------------------
        # Generate assembly
        # ---------------------------------------------------------------------

        run_logged "Compile $base.c -> assembly" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -S "$src_dir/src/$src_rel" \
            -o "$out_dir/asm/$base.s" \
            || return 1


        # ---------------------------------------------------------------------
        # Generate object file
        # ---------------------------------------------------------------------

        run_logged "Compile $base.c -> object" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -c "$src_dir/src/$src_rel" \
            -o "$out_dir/obj/$base.o" \
            || return 1

        objs+=("$out_dir/obj/$base.o")
    fi


    ###########################################################################
    #                 APPLICATION SOURCE: mcal/gpio_driver.c                   #
    ###########################################################################

    # Same rationale as the mcal/rcc_driver.c block above: this file lives in
    # src/mcal/, not directly in src/, so "src_rel" carries the real path
    # while "base" names this file's own distinct output artifacts.
    #
    # Only zcu1-discovery has this file today (ZCU-2 uses Zephyr's own build
    # system instead of this script).

    if [ "$target" = "zcu1-discovery" ]; then

        base=gpio_driver
        src_rel="mcal/gpio_driver.c"

        # ---------------------------------------------------------------------
        # Preprocess C source
        # ---------------------------------------------------------------------

        run_logged "Preprocess $base.c" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -E "$src_dir/src/$src_rel" \
            -o "$out_dir/preprocessed/$base.i" \
            || return 1


        # ---------------------------------------------------------------------
        # Generate assembly
        # ---------------------------------------------------------------------

        run_logged "Compile $base.c -> assembly" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -S "$src_dir/src/$src_rel" \
            -o "$out_dir/asm/$base.s" \
            || return 1


        # ---------------------------------------------------------------------
        # Generate object file
        # ---------------------------------------------------------------------

        run_logged "Compile $base.c -> object" \
            "$CC" $CFLAGS \
            -I"$src_dir/inc" \
            -c "$src_dir/src/$src_rel" \
            -o "$out_dir/obj/$base.o" \
            || return 1

        objs+=("$out_dir/obj/$base.o")
    fi


    ###########################################################################
    #                         STARTUP SOURCE: startup.s                        #
    ###########################################################################

    base=startup

    # Preserve a copy of the startup assembly in the build output directory
    # for traceability and inspection.

    cp "$src_dir/src/$base.s" "$out_dir/asm/$base.s"


    # -------------------------------------------------------------------------
    # Assemble startup source
    # -------------------------------------------------------------------------

    run_logged "Assemble $base.s -> object" \
        "$CC" $CPU_FLAGS \
        -c "$src_dir/src/$base.s" \
        -o "$out_dir/obj/$base.o" \
        || return 1

    objs+=("$out_dir/obj/$base.o")


    ###########################################################################
    #                         LINKER SCRIPT SELECTION                          #
    ###########################################################################

    # The linker script is selected explicitly for each target.
    #
    # This prevents accidental use of an incorrect MCU memory layout.

    case "$target" in

        zcu1-discovery)
            LD_SCRIPT="STM32F407VG_FLASH.ld"
            ;;

        zcu2-nucleo)
            LD_SCRIPT="STM32F446RE_FLASH.ld"
            ;;

        *)
            echo "${RED}Unknown target for linker script mapping: $target${RESET}"
            return 1
            ;;
    esac


    ###########################################################################
    #                              LINK ELF                                    #
    ###########################################################################

    run_logged "Link ${target}.elf" \
        "$CC" $CPU_FLAGS \
        -T"$src_dir/linker/$LD_SCRIPT" \
        -nostdlib \
        -Wl,--gc-sections \
        -Wl,-Map="$out_dir/map/${target}.map" \
        -o "$out_dir/elf/${target}.elf" \
        "${objs[@]}" \
        || return 1


    ###########################################################################
    #                         GENERATE BINARY                                  #
    ###########################################################################

    run_logged "Generate ${target}.bin" \
        "$OBJCOPY" \
        -O binary \
        "$out_dir/elf/${target}.elf" \
        "$out_dir/bin/${target}.bin" \
        || return 1


    ###########################################################################
    #                             SIZE REPORT                                  #
    ###########################################################################

    log_step "Size report"

    "$SIZE" \
        "$out_dir/elf/${target}.elf" \
        | tee -a "$LOGFILE"


    ###########################################################################
    #                            BUILD SUCCESS                                 #
    ###########################################################################

    echo ""
    echo "${GREEN}${BOLD}=== BUILD SUCCEEDED: $target ===${RESET}"
    echo "  ELF: $out_dir/elf/${target}.elf"
    echo "  BIN: $out_dir/bin/${target}.bin"
    echo "  MAP: $out_dir/map/${target}.map"
    echo "  Log: $LOGFILE"

    return 0
}


###############################################################################
#                             TARGET DISPATCH                                 #
###############################################################################

case "$TARGET" in

    zcu1-discovery|zcu2-nucleo)

        build_target "$TARGET" || exit 1
        ;;

    all)

        build_target zcu1-discovery || exit 1
        build_target zcu2-nucleo || exit 1
        ;;

    *)

        usage
        ;;

esac