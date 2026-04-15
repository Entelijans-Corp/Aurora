const std = @import("std");

pub const Permissions = packed struct(u8) {
    read: bool = false,
    write: bool = false,
    transfer: bool = false,
    inspect: bool = false,
    mutate: bool = false,
    execute: bool = false,
    _reserved: u2 = 0,

    pub fn mask(self: Permissions) u8 {
        return @bitCast(self);
    }

    pub fn includes(self: Permissions, other: Permissions) bool {
        const have = self.mask();
        const required = other.mask();
        return (have & required) == required;
    }

    pub fn describe(self: Permissions, buffer: *[64]u8) []const u8 {
        const entries = [_]struct {
            enabled: bool,
            label: []const u8,
        }{
            .{ .enabled = self.read, .label = "read" },
            .{ .enabled = self.write, .label = "write" },
            .{ .enabled = self.transfer, .label = "transfer" },
            .{ .enabled = self.inspect, .label = "inspect" },
            .{ .enabled = self.mutate, .label = "mutate" },
            .{ .enabled = self.execute, .label = "execute" },
        };

        var index: usize = 0;
        for (entries) |entry| {
            if (!entry.enabled) continue;
            if (index != 0) {
                buffer[index] = ',';
                index += 1;
            }
            std.mem.copyForwards(u8, buffer[index .. index + entry.label.len], entry.label);
            index += entry.label.len;
        }

        if (index == 0) {
            const label = "none";
            std.mem.copyForwards(u8, buffer[0..label.len], label);
            return buffer[0..label.len];
        }

        return buffer[0..index];
    }
};

pub const Capability = struct {
    id: u32,
    owner_process_id: u32,
    object_id: u32,
    permissions: Permissions,
    generation: u32 = 1,
};

test "permission inclusion matches bit mask expectations" {
    const full = Permissions{
        .read = true,
        .write = true,
        .transfer = true,
        .inspect = true,
    };

    try std.testing.expect(full.includes(.{ .read = true }));
    try std.testing.expect(full.includes(.{ .read = true, .inspect = true }));
    try std.testing.expect(!full.includes(.{ .execute = true }));
}
