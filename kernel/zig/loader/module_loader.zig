const std = @import("std");

pub const ModuleService = enum {
    scheduler,
    diagnostics,
};

pub const ModuleHandler = *const fn (context: *anyopaque) anyerror!void;

pub const ModuleSpec = struct {
    name: []const u8,
    service: ModuleService,
    version: u32,
    description: []const u8,
    handler: ModuleHandler,
};

pub const ModuleRecord = struct {
    name: []const u8,
    service: ModuleService,
    version: u32,
    description: []const u8,
    handler: ModuleHandler,
};

pub const ModuleLoader = struct {
    modules: std.ArrayListUnmanaged(ModuleRecord) = .{},

    pub fn deinit(self: *ModuleLoader, allocator: std.mem.Allocator) void {
        for (self.modules.items) |module| {
            allocator.free(module.name);
            allocator.free(module.description);
        }
        self.modules.deinit(allocator);
    }

    pub fn registerOrReplace(self: *ModuleLoader, allocator: std.mem.Allocator, spec: ModuleSpec) !bool {
        const owned_name = try allocator.dupe(u8, spec.name);
        errdefer allocator.free(owned_name);

        const owned_description = try allocator.dupe(u8, spec.description);
        errdefer allocator.free(owned_description);

        if (self.indexOf(spec.service)) |index| {
            allocator.free(self.modules.items[index].name);
            allocator.free(self.modules.items[index].description);
            self.modules.items[index] = .{
                .name = owned_name,
                .service = spec.service,
                .version = spec.version,
                .description = owned_description,
                .handler = spec.handler,
            };
            return true;
        }

        try self.modules.append(allocator, .{
            .name = owned_name,
            .service = spec.service,
            .version = spec.version,
            .description = owned_description,
            .handler = spec.handler,
        });
        return false;
    }

    pub fn get(self: *const ModuleLoader, service: ModuleService) ?ModuleRecord {
        if (self.indexOf(service)) |index| {
            return self.modules.items[index];
        }
        return null;
    }

    pub fn invoke(self: *const ModuleLoader, service: ModuleService, context: *anyopaque) !void {
        const module = self.get(service) orelse return error.ModuleNotFound;
        try module.handler(context);
    }

    pub fn items(self: *const ModuleLoader) []const ModuleRecord {
        return self.modules.items;
    }

    fn indexOf(self: *const ModuleLoader, service: ModuleService) ?usize {
        for (self.modules.items, 0..) |module, index| {
            if (module.service == service) {
                return index;
            }
        }
        return null;
    }
};

