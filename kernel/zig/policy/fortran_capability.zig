const capability_mod = @import("../core/capability.zig");
const std = @import("std");

pub extern fn aurora_capability_can_transfer(permission_mask: c_int, source_owner: c_int, new_owner: c_int, generation: c_int) c_int;
pub extern fn aurora_capability_risk_score(permission_mask: c_int, generation: c_int) c_int;

pub fn canTransfer(capability: capability_mod.Capability, new_owner_process_id: u32) bool {
    return aurora_capability_can_transfer(
        @intCast(capability.permissions.mask()),
        @intCast(capability.owner_process_id),
        @intCast(new_owner_process_id),
        @intCast(capability.generation),
    ) != 0;
}

pub fn riskScore(capability: capability_mod.Capability) u8 {
    return @intCast(aurora_capability_risk_score(
        @intCast(capability.permissions.mask()),
        @intCast(capability.generation),
    ));
}

test "fortran capability policy gates delegation and scores authority" {
    const transferable = capability_mod.Capability{
        .id = 1,
        .owner_process_id = 1,
        .object_id = 7,
        .permissions = .{
            .read = true,
            .write = true,
            .transfer = true,
            .inspect = true,
        },
        .generation = 2,
    };

    const read_only = capability_mod.Capability{
        .id = 2,
        .owner_process_id = 1,
        .object_id = 8,
        .permissions = .{
            .read = true,
        },
        .generation = 1,
    };

    try std.testing.expect(canTransfer(transferable, 3));
    try std.testing.expect(!canTransfer(transferable, 1));
    try std.testing.expect(!canTransfer(read_only, 3));
    try std.testing.expect(riskScore(transferable) > riskScore(read_only));
}

