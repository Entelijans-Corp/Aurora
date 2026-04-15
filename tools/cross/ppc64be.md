# PPC64-BE Target Notes

Aurora's long-term primary architecture is PowerPC64 Big Endian.

## Planned Build Inputs

- Zig target descriptor for `powerpc64` big-endian freestanding output
- linker script for early boot image placement
- assembly boot entry and trap veneers under `kernel/asm/`
- QEMU bring-up command line for `ppc64`

## Expected Milestones

1. host prototype validates kernel interfaces
2. ppc64-be linker script lands
3. serial-only boot path comes up in QEMU
4. capability kernel objects become visible through the debug channel
5. Fortran scheduler policy is linked into the freestanding image

## Practical Development Advice

Until the freestanding target exists, develop against the host prototype first and keep architecture-specific state inside `kernel/zig/arch/` plus `kernel/asm/`. That keeps the portability story intact and prevents the host path from hardcoding x86 assumptions into the kernel model.
