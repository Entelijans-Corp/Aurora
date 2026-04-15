pub const KernelObjectKind = enum {
    process,
    endpoint,
    memory_region,
    module,
    capability_space,
};

pub const KernelObject = struct {
    id: u32,
    kind: KernelObjectKind,
    name: []const u8,
    generation: u32 = 1,
    owner_process_id: ?u32,
    live: bool = true,
};

