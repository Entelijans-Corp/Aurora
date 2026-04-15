# Capability Model

Aurora's security model is object-capability based. Every authority in the system is represented as a capability that names a kernel object and the actions allowed on that object.

## Capability Shape

The current prototype models a capability as:

- `id`: a unique capability handle
- `owner_process_id`: the process currently holding the capability
- `object_id`: the kernel object being referenced
- `permissions`: the authority granted over that object
- `generation`: a monotonically increasing lineage value

The permission bits currently tracked are:

- `read`
- `write`
- `transfer`
- `inspect`
- `mutate`
- `execute`

## Security Properties

The prototype is intentionally small, but it already preserves the behaviors we care about:

- A capability cannot be minted for an unknown object.
- A capability cannot be transferred unless the source capability includes `transfer`.
- Introspection is represented as a distinct permission rather than folded into general read access.
- Ownership is explicit, which keeps transfer semantics easy to reason about.

## Design Direction

The present implementation is a stepping stone toward:

- sealed capabilities for constrained delegation
- revocation trees for live component replacement
- endpoint send/receive capabilities
- memory capabilities with region-scoped authority
- capability-derived module loading permissions

## Planned Enforcement Changes

As Aurora moves beyond the host prototype, the next changes should be:

1. split endpoint permissions into send/receive/grant
2. attach capability derivation metadata
3. make capabilities opaque outside the kernel
4. route introspection through inspect-only capabilities
5. add revocation hooks to the live module loader

