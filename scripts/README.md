# scripts

> **Author:** Chittaranjan Baral ([@SJLNS](https://github.com/SJLNS))
> **Version:** v0.1.0
> **Last updated:** 2026-08-08

Build/dev tooling that isn't specific to one board.

## buildenv.sh

Structured build wrapper for the ZCU firmware targets. Generates every
intermediate compilation artifact into its own folder and writes a
sequenced, timestamped log per run. On failure it stops immediately with a
loud banner naming the failing step and the log file to check.

**Run from Git Bash (not cmd — this is a bash script), from the repo root:**

```bash
cd <path-to-repo-root>/SDV_Replica_POC
./scripts/buildenv.sh <zcu1-discovery|zcu2-nucleo|all> [clean]
```

Output lands in `build-output/<target>/` (gitignored — regenerated every run,
never committed):

```
build-output/<target>/
├── preprocessed/   .i files (macro-expanded source)
├── asm/            .s files (compiler-generated assembly + copy of startup.s)
├── obj/            .o files
├── elf/            linked .elf
├── bin/            raw .bin (for flashing)
├── map/            linker .map file
└── logs/           one timestamped build_YYYYMMDD_HHMMSS.log per run
```

Requires `arm-none-eabi-gcc`, `arm-none-eabi-objcopy`, and `arm-none-eabi-size`
on `PATH` (see Execution Guide Section 2 for install steps).
