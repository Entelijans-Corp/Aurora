const std = @import("std");
const capability_mod = @import("capability.zig");
const introspection = @import("introspection.zig");
const ipc = @import("ipc.zig");
const object_mod = @import("object.zig");
const module_loader = @import("../loader/module_loader.zig");
const address_space = @import("../memory/address_space.zig");
const platform = @import("../arch/platform.zig");

pub const KernelConfig = struct {
    max_objects: usize = 64,
    max_capabilities: usize = 128,
    architecture: platform.Architecture = .host,
};

pub const Kernel = struct {
    allocator: std.mem.Allocator,
    config: KernelConfig,
    next_object_id: u32 = 1,
    next_capability_id: u32 = 1,
    objects: std.ArrayListUnmanaged(object_mod.KernelObject) = .{},
    capabilities: std.ArrayListUnmanaged(capability_mod.Capability) = .{},
    endpoints: std.ArrayListUnmanaged(ipc.Endpoint) = .{},
    address_space_map: address_space.AddressSpace = .{},
    modules: module_loader.ModuleLoader = .{},
    scheduler_ticks: usize = 0,

    pub fn init(allocator: std.mem.Allocator, config: KernelConfig) !Kernel {
        var kernel = Kernel{
            .allocator = allocator,
            .config = config,
        };
        try kernel.objects.ensureTotalCapacity(allocator, config.max_objects);
        try kernel.capabilities.ensureTotalCapacity(allocator, config.max_capabilities);
        return kernel;
    }

    pub fn deinit(self: *Kernel) void {
        for (self.objects.items) |object| {
            self.allocator.free(object.name);
        }
        self.objects.deinit(self.allocator);
        self.capabilities.deinit(self.allocator);

        for (self.endpoints.items) |*endpoint| {
            endpoint.deinit(self.allocator);
        }
        self.endpoints.deinit(self.allocator);
        self.address_space_map.deinit(self.allocator);
        self.modules.deinit(self.allocator);
    }

    pub fn createObject(
        self: *Kernel,
        kind: object_mod.KernelObjectKind,
        name: []const u8,
        owner_process_id: ?u32,
    ) !u32 {
        if (owner_process_id) |owner| {
            if (!self.hasObject(owner)) {
                return error.UnknownOwner;
            }
        }

        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        const object_id = self.next_object_id;
        self.next_object_id += 1;

        try self.objects.append(self.allocator, .{
            .id = object_id,
            .kind = kind,
            .name = owned_name,
            .owner_process_id = owner_process_id,
        });

        if (kind == .endpoint) {
            try self.endpoints.append(self.allocator, ipc.Endpoint.init(object_id));
        }

        return object_id;
    }

    pub fn hasObject(self: *const Kernel, object_id: u32) bool {
        for (self.objects.items) |object| {
            if (object.id == object_id) {
                return true;
            }
        }
        return false;
    }

    pub fn mintCapability(
        self: *Kernel,
        owner_process_id: u32,
        object_id: u32,
        permissions: capability_mod.Permissions,
    ) !capability_mod.Capability {
        if (!self.hasObject(owner_process_id)) {
            return error.UnknownOwner;
        }
        if (!self.hasObject(object_id)) {
            return error.UnknownObject;
        }

        const capability = capability_mod.Capability{
            .id = self.next_capability_id,
            .owner_process_id = owner_process_id,
            .object_id = object_id,
            .permissions = permissions,
        };
        self.next_capability_id += 1;
        try self.capabilities.append(self.allocator, capability);
        return capability;
    }

    pub fn transferCapability(self: *Kernel, capability_id: u32, new_owner_process_id: u32) !capability_mod.Capability {
        if (!self.hasObject(new_owner_process_id)) {
            return error.UnknownOwner;
        }

        const source = self.getCapability(capability_id) orelse return error.UnknownCapability;
        if (!source.permissions.transfer) {
            return error.TransferDenied;
        }

        const capability = capability_mod.Capability{
            .id = self.next_capability_id,
            .owner_process_id = new_owner_process_id,
            .object_id = source.object_id,
            .permissions = source.permissions,
            .generation = source.generation + 1,
        };
        self.next_capability_id += 1;
        try self.capabilities.append(self.allocator, capability);
        return capability;
    }

    pub fn addRegion(
        self: *Kernel,
        name: []const u8,
        base: u64,
        size: u64,
        permissions: address_space.MemoryPermissions,
    ) !void {
        try self.address_space_map.addRegion(self.allocator, name, base, size, permissions);
    }

    pub fn sendMessage(self: *Kernel, sender_process_id: u32, endpoint_object_id: u32, text: []const u8) !void {
        if (!self.hasObject(sender_process_id)) {
            return error.UnknownOwner;
        }

        var endpoint = self.getEndpoint(endpoint_object_id) orelse return error.UnknownEndpoint;
        try endpoint.send(self.allocator, sender_process_id, text);
    }

    pub fn receiveMessage(self: *Kernel, endpoint_object_id: u32) ?ipc.Message {
        var endpoint = self.getEndpoint(endpoint_object_id) orelse return null;
        return endpoint.receive();
    }

    pub fn registerModule(self: *Kernel, spec: module_loader.ModuleSpec) !bool {
        return self.modules.registerOrReplace(self.allocator, spec);
    }

    pub fn invokeService(self: *Kernel, service: module_loader.ModuleService) !void {
        try self.modules.invoke(service, self);
    }

    pub fn noteSchedulerTick(self: *Kernel, ticks: usize) void {
        self.scheduler_ticks += ticks;
    }

    pub fn totalQueuedMessages(self: *const Kernel) usize {
        var total: usize = 0;
        for (self.endpoints.items) |endpoint| {
            total += endpoint.queued();
        }
        return total;
    }

    pub fn getServiceModule(self: *const Kernel, service: module_loader.ModuleService) ?module_loader.ModuleRecord {
        return self.modules.get(service);
    }

    pub fn inspect(self: *const Kernel, writer: anytype) !void {
        try introspection.render(writer, .{
            .architecture = platform.describe(self.config.architecture),
            .scheduler_ticks = self.scheduler_ticks,
            .objects = self.objects.items,
            .capabilities = self.capabilities.items,
            .endpoints = self.endpoints.items,
            .regions = self.address_space_map.items(),
            .modules = self.modules.items(),
        });
    }

    fn getCapability(self: *const Kernel, capability_id: u32) ?capability_mod.Capability {
        for (self.capabilities.items) |capability| {
            if (capability.id == capability_id) {
                return capability;
            }
        }
        return null;
    }

    fn getEndpoint(self: *Kernel, endpoint_object_id: u32) ?*ipc.Endpoint {
        for (self.endpoints.items) |*endpoint| {
            if (endpoint.object_id == endpoint_object_id) {
                return endpoint;
            }
        }
        return null;
    }
};

test "capabilities can be transferred across processes" {
    var kernel = try Kernel.init(std.testing.allocator, .{});
    defer kernel.deinit();

    const init_pid = try kernel.createObject(.process, "init", null);
    const shell_pid = try kernel.createObject(.process, "shell", init_pid);
    const endpoint = try kernel.createObject(.endpoint, "control", init_pid);

    const root_capability = try kernel.mintCapability(init_pid, endpoint, .{
        .read = true,
        .write = true,
        .transfer = true,
        .inspect = true,
    });

    const delegated = try kernel.transferCapability(root_capability.id, shell_pid);
    try std.testing.expectEqual(endpoint, delegated.object_id);
    try std.testing.expectEqual(shell_pid, delegated.owner_process_id);
    try std.testing.expectEqual(root_capability.generation + 1, delegated.generation);
}

test "services can be hot swapped" {
    const DemoState = struct {
        ticks: usize = 0,
    };

    const Harness = struct {
        fn tickSlow(context: *anyopaque) !void {
            const state: *DemoState = @ptrCast(@alignCast(context));
            state.ticks += 1;
        }

        fn tickFast(context: *anyopaque) !void {
            const state: *DemoState = @ptrCast(@alignCast(context));
            state.ticks += 4;
        }
    };

    var loader = module_loader.ModuleLoader{};
    defer loader.deinit(std.testing.allocator);

    var state = DemoState{};
    try std.testing.expect(!(try loader.registerOrReplace(std.testing.allocator, .{
        .name = "bootstrap",
        .service = .scheduler,
        .version = 1,
        .description = "boot scheduler",
        .handler = Harness.tickSlow,
    })));

    try loader.invoke(.scheduler, &state);
    try std.testing.expectEqual(@as(usize, 1), state.ticks);

    try std.testing.expect(try loader.registerOrReplace(std.testing.allocator, .{
        .name = "transparent",
        .service = .scheduler,
        .version = 2,
        .description = "replacement scheduler",
        .handler = Harness.tickFast,
    }));

    try loader.invoke(.scheduler, &state);
    try std.testing.expectEqual(@as(usize, 5), state.ticks);
}
