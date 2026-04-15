# AURORA OS

*A transparent, capability-secure, live-evolving operating system built with Zig and Fortran*

## Overview

Aurora OS is a research operating system prototype organized around five goals:

1. Full system transparency
2. Capability-based security
3. Live system evolution
4. High-performance execution
5. Multi-architecture portability with `ppc64-be` as the long-term primary target

This repository now contains the first real scaffold behind that design: a host-runnable kernel prototype, a Zig build, multiple Fortran policy modules, architecture stubs, and docs that map the design into code.

## What Exists Today

The current prototype is not a bootable kernel yet. It is a concrete implementation of the core ideas so the project can evolve from real interfaces instead of staying trapped in the README.

Included now:

- a Zig build entrypoint in `build.zig`
- a host-runnable kernel prototype in `kernel/zig/main.zig`
- kernel object and capability management
- endpoint-style IPC with queue tracking
- a hot-swappable module loader for live service replacement
- a Fortran scheduler policy linked directly into the Zig build from `kernel/fortran/scheduler/round_robin.f90`
- a Fortran capability policy layer in `kernel/fortran/capability/policy.f90`
- a Fortran transparency and telemetry layer in `kernel/fortran/transparency/telemetry.f90`
- a minimal Fortran runtime shim in `runtime/fortran_min/aurora_runtime.f90`
- ppc64 assembly placeholders for boot and trap entry

## Architecture

Aurora still follows the same hybrid shape:

```text
+--------------------------------------+
| Fortran Userland / Runtime           |
+--------------------------------------+
| Fortran Kernel Services              |
| - Scheduler policy                   |
| - Allocators                         |
| - Filesystems                        |
| - Networking                         |
| - Capability-aware policy            |
+--------------------------------------+
| Zig Kernel Mechanism                 |
| - Object model                       |
| - IPC primitives                     |
| - Capability minting/transfer        |
| - Live module registry               |
| - Introspection                      |
+--------------------------------------+
| Architecture Layer (Zig + Assembly)  |
| - Boot code                          |
| - Trap handlers                      |
| - Register management                |
+--------------------------------------+
| Hardware / Emulation                 |
+--------------------------------------+
```

## Project Structure

```text
kernel/
  zig/
    arch/                 Target descriptors and architecture glue
    core/                 Object model, IPC, capabilities, introspection
    loader/               Hot-swappable service registry
    memory/               Memory-region tracking
    policy/               Zig bridges into Fortran policy code
    main.zig              Host prototype entrypoint
  fortran/
    capability/           Capability delegation and audit policy
    scheduler/            Policy-oriented scheduler logic
    transparency/         Kernel telemetry and transparency scoring
  asm/
    boot/ppc64/           Early boot stubs
    traps/ppc64/          Trap stubs
runtime/
  fortran_min/            Minimal runtime helpers for policy code
tools/
  build/                  Local build helpers
  cross/                  Target notes and cross-build guidance
docs/
  architecture.md
  capability_model.md
  live_reload.md
```

## Running the Prototype

If `zig` is installed:

```powershell
zig build run
```

To run tests:

```powershell
zig build test
```

To use the helper script:

```powershell
.\tools\build\build.ps1 -Run
```

To drive the Linux toolchain from Windows through WSL2:

```powershell
.\tools\build\build-wsl.ps1 -Run
```

To compile the Fortran pieces independently:

```powershell
gfortran -c .\kernel\fortran\scheduler\round_robin.f90
gfortran -c .\kernel\fortran\capability\policy.f90
gfortran -c .\kernel\fortran\transparency\telemetry.f90
gfortran -c .\runtime\fortran_min\aurora_runtime.f90
```

## Current Status

Stage: prototype scaffold

Working in code today:

- capability minting and transfer
- object registration
- IPC queue modeling
- live module replacement
- Zig calling into a Fortran scheduler policy
- Fortran-backed capability delegation rules and risk scoring
- Fortran-backed kernel telemetry and transparency scoring
- transparent kernel inspection

Still ahead:

- real freestanding boot
- ppc64-be linker and memory map
- kernel-mode scheduler execution
- MMU and interrupt control

## Design Notes

Aurora keeps a strict mechanism-versus-policy split:

- Zig handles mechanism
- Fortran handles policy
- Assembly handles hardware entry

That separation is already reflected in the repo layout so the system can scale without collapsing into one monolithic kernel tree.
