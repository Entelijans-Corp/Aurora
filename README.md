# AURORA OS

*A transparent, capability-secure, live-evolving operating system built with Zig and Fortran*

---

## Overview

**Aurora OS** is a research-grade operating system designed around five core principles:

1. **Full System Transparency**
   Every component of the system is inspectable, modifiable, and observable at runtime.

2. **High Performance**
   Achieves performance comparable to traditional systems through modern compilation techniques and low-level control.

3. **Live System Evolution**
   The system supports hot-swapping of components, enabling updates, patches, and feature additions without requiring restarts.

4. **Capability-Based Security**
   Security is enforced through unforgeable capabilities rather than identity-based access control lists.

5. **Multi-Architecture Support**
   Designed for portability, with **PowerPC64 Big Endian (ppc64-be)** as the primary target.

---

## Architecture

Aurora OS follows a **hybrid microkernel architecture**:

```
+--------------------------------------+
| Fortran Userland / Runtime           |
+--------------------------------------+
| Fortran Kernel Services              |
| - Scheduler (policy)                 |
| - Memory allocators                  |
| - Filesystems                        |
| - Networking stack                   |
| - Capability system                  |
+--------------------------------------+
| Zig Microkernel                      |
| - IPC primitives                     |
| - Threading & context switching      |
| - Virtual memory (MMU control)       |
| - Interrupt handling                 |
+--------------------------------------+
| Architecture Layer (Zig + Assembly)  |
| - Boot code                          |
| - Trap handlers                      |
| - Register management               |
+--------------------------------------+
| Hardware (ppc64-be primary)          |
+--------------------------------------+
```

---

## Language Strategy

Aurora OS intentionally separates responsibilities:

* **Zig** → Low-level control (mechanism)
* **Fortran** → System logic and services (policy)
* **Assembly** → Hardware entry points

### Why Fortran?

Fortran provides:

* Predictable performance
* Strong structure for system logic
* Excellent numerical and data-processing capabilities
* A foundation for future scientific and high-performance workloads

---

## Key Features

### 1. Transparent Runtime System

Aurora exposes all kernel objects through a live introspection system:

* Inspect memory structures in real time
* Modify system behavior dynamically
* Query kernel state without special privileges

---

### 2. Live Module System

Aurora supports dynamic system evolution:

* Load/unload modules at runtime
* Replace subsystems without reboot
* Function pointer redirection for hot-swapping
* Version-aware symbol resolution

---

### 3. Capability-Based Security Model

Aurora eliminates ACLs entirely.

Each process operates using **capabilities**:

```
Capability = (Object Reference + Permissions)
```

Properties:

* Unforgeable
* Explicitly transferable
* Fine-grained access control

---

### 4. High-Performance Execution

* Compiled with aggressive optimization (`-O3`, LTO, PGO)
* Minimal abstraction overhead
* Tight control over memory and execution paths

---

### 5. Multi-Architecture Design

Primary architecture:

* PowerPC64 Big Endian (ppc64-be)

Planned support:

* x86_64
* ARM64

Architecture-specific code is isolated in dedicated modules.

---

## Project Structure

```
aurora/
├── kernel/
│   ├── zig/
│   │   ├── core/              # Kernel core (IPC, scheduler mechanism)
│   │   ├── memory/            # Virtual memory management
│   │   ├── arch/              # Architecture-specific code
│   │   └── loader/            # Module loader
│   │
│   ├── fortran/
│   │   ├── scheduler/         # Scheduling policy
│   │   ├── memory/            # Allocators
│   │   ├── fs/                # Filesystems
│   │   ├── net/               # Networking stack
│   │   └── capability/        # Security model
│   │
│   └── asm/
│       ├── boot/              # Boot code
│       └── traps/             # Interrupt/trap handlers
│
├── runtime/
│   └── fortran_min/           # Minimal Fortran runtime
│
├── tools/
│   ├── build/                 # Build scripts
│   └── cross/                 # Cross-compilation configs
│
├── docs/
│   ├── architecture.md
│   ├── capability_model.md
│   └── live_reload.md
│
└── README.md
```

---

## Build System

Aurora uses:

* Zig build system (`zig build`)
* GFortran / Flang for Fortran components
* Cross-compilation targeting `ppc64-be`

### Requirements

* Zig (latest stable)
* Fortran compiler (gfortran or flang)
* QEMU (for emulation)
* PowerPC64 cross toolchain (optional for native target)

---

## Development Roadmap

### Phase 1 — Bootable Kernel

* Bootloader integration
* Serial output
* Basic memory initialization

### Phase 2 — Fortran Integration

* Call Fortran from Zig kernel
* Minimal runtime support
* Static linking

### Phase 3 — Capability System

* Kernel object model
* Capability creation and transfer
* IPC mechanisms

### Phase 4 — Live Module Loader

* Dynamic linking system
* Runtime symbol resolution
* Safe module replacement

### Phase 5 — System Services

* Scheduler (policy)
* Memory allocators
* Filesystem
* Networking

### Phase 6 — Transparency Layer

* Introspection APIs
* Live system shell
* Debug interface

---

## Design Philosophy

Aurora OS is built on a strict separation:

> **Mechanism vs Policy**

* Mechanism (Zig): minimal, deterministic, hardware-facing
* Policy (Fortran): expressive, dynamic, evolvable

This enables:

* safer system evolution
* clearer reasoning about behavior
* reduced kernel complexity

---

## Inspirations

Aurora draws conceptual influence from:

* seL4 — minimal, secure kernel design
* Plan 9 — system transparency and simplicity
* EROS — capability-based security
* Smalltalk — live system introspection

---

## Status

**Stage:** Early Architecture / Prototype Design

Aurora is currently in the design and early prototyping phase. Core interfaces and architecture are under active development.

---

## Contributing

This project is currently experimental and not yet open for external contributions. Documentation and interfaces will stabilize before broader collaboration begins.

---

## License

TBD

---

## Vision

Aurora OS is not just an operating system.

It is an attempt to build a system that is:

* Fully understandable
* Fully modifiable
* Always running
* Never opaque

A system where **the boundary between developer and machine disappears**.

---
