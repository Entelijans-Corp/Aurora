pub const Architecture = enum {
    host,
    ppc64_be,
    x86_64,
    arm64,
};

pub fn describe(architecture: Architecture) []const u8 {
    return switch (architecture) {
        .host => "host-simulator",
        .ppc64_be => "powerpc64-big-endian",
        .x86_64 => "x86_64",
        .arm64 => "arm64",
    };
}

