#!/usr/bin/env bash
#
# buildenv.sh — build wrapper for ZCU firmware targets.
#
# What it does differently from a plain `cmake --build`:
#   - Every intermediate artifact gets its own folder: preprocessed (.i),
#     assembly (.s), objects (.o), elf, bin, map.
#   - Every build run writes a timestamped, numbered-step log file.
#   - The build sequence (what ran, in what order, exact command) is recorded
#     in that log, not just the pass/fail result.
#   - Any failing step stops the build immediately and prints an impossible-
#     to-miss banner, both on screen and in the log, naming the exact step
#     and log file to go read.
#
# USAGE (run from Git Bash — NOT cmd, this is a bash script — from the repo root):
#   ./scripts/buildenv.sh <zcu1-discovery|zcu2-nucleo|all> [clean]
#
# EXAMPLES:
#   ./scripts/buildenv.sh zcu1-discovery
#   ./scripts/buildenv.sh all clean

set -uo pipefail   # deliberately no -e: we handle/report failures ourselves

TARGET="${1:-}"
CLEAN="${2:-}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
SIZE=arm-none-eabi-size

CPU_FLAGS="-mcpu=cortex-m4 -mthumb -mfloat-abi=soft"
CFLAGS="$CPU_FLAGS -Wall -Wextra -ffreestanding -O0 -g"

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

STEP_NUM=0
LOGFILE=""

usage() {
  echo "Usage: $0 <zcu1-discovery|zcu2-nucleo|all> [clean]"
  exit 1
}
[ -z "$TARGET" ] && usage

banner_error() {
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

log_step() {
  STEP_NUM=$((STEP_NUM+1))
  local desc="$1"
  {
    echo ""
    echo "[$STEP_NUM] $(date '+%Y-%m-%d %H:%M:%S') - $desc"
  } >> "$LOGFILE"
}

run_logged() {
  local desc="$1"; shift
  log_step "$desc"
  echo "CMD: $*" >> "$LOGFILE"
  if "$@" >>"$LOGFILE" 2>&1; then
    echo "  ${GREEN}OK${RESET}  $desc"
    return 0
  else
    local rc=$?
    banner_error "$desc FAILED (exit $rc) - see $LOGFILE"
    return "$rc"
  fi
}

build_target() {
  local target="$1"
  local src_dir="$REPO_ROOT/zcu/$target"
  local out_dir="$REPO_ROOT/build-output/$target"

  if [ ! -d "$src_dir" ]; then
    echo "${RED}No such target: $target (expected $src_dir)${RESET}"
    return 1
  fi
  [ "$CLEAN" = "clean" ] && rm -rf "$out_dir"

  mkdir -p "$out_dir"/preprocessed "$out_dir"/asm "$out_dir"/obj "$out_dir"/elf "$out_dir"/bin "$out_dir"/map "$out_dir"/logs
  LOGFILE="$out_dir/logs/build_$(date '+%Y%m%d_%H%M%S').log"
  : > "$LOGFILE"
  STEP_NUM=0

  echo "${BOLD}=== Building $target ===${RESET}"
  echo "Log file: $LOGFILE"
  echo "=== Building $target - $(date) ===" >> "$LOGFILE"

  local objs=()
  local base

  base=main
  run_logged "Preprocess $base.c" \
    "$CC" $CFLAGS -I"$src_dir/inc" -E "$src_dir/src/$base.c" -o "$out_dir/preprocessed/$base.i" || return 1
  run_logged "Compile $base.c -> assembly" \
    "$CC" $CFLAGS -I"$src_dir/inc" -S "$src_dir/src/$base.c" -o "$out_dir/asm/$base.s" || return 1
  run_logged "Compile $base.c -> object" \
    "$CC" $CFLAGS -I"$src_dir/inc" -c "$src_dir/src/$base.c" -o "$out_dir/obj/$base.o" || return 1
  objs+=("$out_dir/obj/$base.o")

  base=startup
  cp "$src_dir/src/$base.s" "$out_dir/asm/$base.s"
  run_logged "Assemble $base.s -> object" \
    "$CC" $CPU_FLAGS -c "$src_dir/src/$base.s" -o "$out_dir/obj/$base.o" || return 1
  objs+=("$out_dir/obj/$base.o")

  run_logged "Link ${target}.elf" \
    "$CC" $CPU_FLAGS -T"$src_dir/linker/STM32_GENERIC.ld" -nostdlib -Wl,--gc-sections \
      -Wl,-Map="$out_dir/map/${target}.map" -o "$out_dir/elf/${target}.elf" "${objs[@]}" || return 1

  run_logged "Generate ${target}.bin" \
    "$OBJCOPY" -O binary "$out_dir/elf/${target}.elf" "$out_dir/bin/${target}.bin" || return 1

  log_step "Size report"
  "$SIZE" "$out_dir/elf/${target}.elf" | tee -a "$LOGFILE"

  echo ""
  echo "${GREEN}${BOLD}=== BUILD SUCCEEDED: $target ===${RESET}"
  echo "  ELF: $out_dir/elf/${target}.elf"
  echo "  BIN: $out_dir/bin/${target}.bin"
  echo "  MAP: $out_dir/map/${target}.map"
  echo "  Log: $LOGFILE"
  return 0
}

case "$TARGET" in
  zcu1-discovery|zcu2-nucleo)
    build_target "$TARGET" || exit 1 ;;
  all)
    build_target zcu1-discovery || exit 1
    build_target zcu2-nucleo || exit 1 ;;
  *)
    usage ;;
esac
