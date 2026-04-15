# Aurora Architecture

Aurora is currently a host-runnable prototype that exercises the operating system's core ideas before the project grows into a freestanding kernel. The implementation is intentionally split along the same boundaries described in the main README:

- Zig owns low-level mechanism, object management, IPC, live module registration, and runtime inspection.
- Fortran owns policy-oriented services such as scheduler heuristics and the minimal runtime surface we expect to call from the kernel.
- Assembly remains isolated to architecture entry points and trap veneers so bring-up work can happen without polluting the higher-level code paths.

## Prototype Layers

### Host Prototype

The current executable is a transparent kernel simulator:

- It creates kernel objects and capabilities.
- It models endpoint-based IPC with queue depth tracking.
- It records memory regions and exposes them through runtime inspection.
- It supports live replacement of kernel services through a hot-swappable module table.

This gives us a concrete place to evolve interfaces while the freestanding boot path is still forming.

### Future Freestanding Path

The target layering remains:

1. `kernel/asm/`
   Architecture-specific boot and trap entry points.
2. `kernel/zig/arch/`
   Register state, MMU control, interrupt plumbing, and target descriptors.
3. `kernel/zig/core/`
   Core kernel mechanism: object model, IPC, capability minting, and module loading.
4. `kernel/fortran/`
   Scheduler policy, filesystems, networking, allocators, and other evolvable services.
5. `runtime/fortran_min/`
   The smallest runtime shims necessary to safely host policy code inside the kernel.

## Why Start With a Host Prototype

Building the interfaces first makes the later freestanding work less risky:

- We can test capability semantics before MMU code exists.
- We can prove hot-swap rules without requiring bootloader work.
- We can validate the Zig/Fortran seam with ordinary toolchains.
- We can generate architecture docs from real code rather than sketches.

## Near-Term Next Steps

1. Add a ppc64-be linker script and boot target in `build.zig`.
2. Introduce a real architecture state object under `kernel/zig/arch/ppc64_be/`.
3. Compile the Fortran scheduler into the Zig build graph.
4. Replace the host-only endpoint queue with kernel message rings.
5. Add a serial console and structured debug channel for early boot.

