const std = @import("std");

pub const MemoryPermissions = packed struct(u8) {
    read: bool = true,
    write: bool = false,
    execute: bool = false,
    device: bool = false,
    _reserved: u4 = 0,

    pub fn describe(self: MemoryPermissions, buffer: *[16]u8) []const u8 {
        buffer[0] = if (self.read) 'r' else '-';
        buffer[1] = if (self.write) 'w' else '-';
        buffer[2] = if (self.execute) 'x' else '-';
        buffer[3] = if (self.device) 'd' else '-';
        return buffer[0..4];
    }
};

pub const MemoryRegion = struct {
    name: []const u8,
    base: u64,
    size: u64,
    permissions: MemoryPermissions,
};

pub const AddressSpace = struct {
    regions: std.ArrayListUnmanaged(MemoryRegion) = .{},

    pub fn deinit(self: *AddressSpace, allocator: std.mem.Allocator) void {
        for (self.regions.items) |region| {
            allocator.free(region.name);
        }
        self.regions.deinit(allocator);
    }

    pub fn addRegion(
        self: *AddressSpace,
        allocator: std.mem.Allocator,
        name: []const u8,
        base: u64,
        size: u64,
        permissions: MemoryPermissions,
    ) !void {
        const owned_name = try allocator.dupe(u8, name);
        errdefer allocator.free(owned_name);

        try self.regions.append(allocator, .{
            .name = owned_name,
            .base = base,
            .size = size,
            .permissions = permissions,
        });
    }

    pub fn items(self: *const AddressSpace) []const MemoryRegion {
        return self.regions.items;
    }
};

