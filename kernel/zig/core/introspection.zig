const capability_mod = @import("capability.zig");
const ipc = @import("ipc.zig");
const object_mod = @import("object.zig");
const module_loader = @import("../loader/module_loader.zig");
const address_space = @import("../memory/address_space.zig");
const fortran_capability = @import("../policy/fortran_capability.zig");
const fortran_telemetry = @import("../policy/fortran_telemetry.zig");

pub const Snapshot = struct {
    architecture: []const u8,
    scheduler_ticks: usize,
    telemetry_profile: fortran_telemetry.KernelProfile,
    objects: []const object_mod.KernelObject,
    capabilities: []const capability_mod.Capability,
    endpoints: []const ipc.Endpoint,
    regions: []const address_space.MemoryRegion,
    modules: []const module_loader.ModuleRecord,
};

pub fn render(writer: anytype, snapshot: Snapshot) !void {
    try writer.print("architecture: {s}\n", .{snapshot.architecture});
    try writer.print("scheduler_ticks: {}\n", .{snapshot.scheduler_ticks});
    try writer.print(
        "telemetry: transparency={} pressure={} evolution={}\n",
        .{
            snapshot.telemetry_profile.transparency_score,
            snapshot.telemetry_profile.pressure_score,
            snapshot.telemetry_profile.evolution_score,
        },
    );

    try writer.print("objects ({})\n", .{snapshot.objects.len});
    for (snapshot.objects) |object| {
        if (object.owner_process_id) |owner| {
            try writer.print(
                "  - id={} kind={s} name={s} owner={} live={}\n",
                .{ object.id, @tagName(object.kind), object.name, owner, object.live },
            );
        } else {
            try writer.print(
                "  - id={} kind={s} name={s} owner=root live={}\n",
                .{ object.id, @tagName(object.kind), object.name, object.live },
            );
        }
    }

    try writer.print("capabilities ({})\n", .{snapshot.capabilities.len});
    for (snapshot.capabilities) |capability| {
        var permissions_buffer: [64]u8 = undefined;
        try writer.print(
            "  - id={} owner={} object={} perms={s} risk={}\n",
            .{
                capability.id,
                capability.owner_process_id,
                capability.object_id,
                capability.permissions.describe(&permissions_buffer),
                fortran_capability.riskScore(capability),
            },
        );
    }

    try writer.print("endpoints ({})\n", .{snapshot.endpoints.len});
    for (snapshot.endpoints) |endpoint| {
        try writer.print("  - object={} queue_depth={}\n", .{ endpoint.object_id, endpoint.queued() });
    }

    try writer.print("memory_regions ({})\n", .{snapshot.regions.len});
    for (snapshot.regions) |region| {
        var permissions_buffer: [16]u8 = undefined;
        try writer.print(
            "  - name={s} base=0x{x} size=0x{x} perms={s}\n",
            .{
                region.name,
                region.base,
                region.size,
                region.permissions.describe(&permissions_buffer),
            },
        );
    }

    try writer.print("modules ({})\n", .{snapshot.modules.len});
    for (snapshot.modules) |module| {
        try writer.print(
            "  - service={s} name={s} version={} description={s}\n",
            .{ @tagName(module.service), module.name, module.version, module.description },
        );
    }
}
