# Live Reload Strategy

Aurora's live evolution story centers on replacing policy without destabilizing mechanism.

## Current Prototype

The Zig prototype contains a `ModuleLoader` that registers one implementation per kernel service. Re-registering a service replaces the previous module in place, which gives us a straightforward model for hot-swapping.

The demo executable shows this with the scheduler:

1. a bootstrap scheduler is registered
2. the scheduler service is invoked once
3. a transparent scheduler replaces the original module
4. the same service is invoked again with different behavior

The result is visible in the scheduler tick counter and in the introspection dump.

## Swap Rules

The current rules are deliberately conservative:

- one active module per service
- replacement is atomic at the registry level
- service invocation fails cleanly when no module is installed
- old module metadata is released when replaced

## Next Iteration

To reach Aurora's intended live-update model, we should add:

- version compatibility checks between modules and kernel ABI
- quiescence points before replacing stateful services
- rollback metadata for failed reloads
- capability checks for module replacement authority
- symbol indirection for multiple service versions in flight

