const std = @import("std");

pub const KernelProfile = struct {
    transparency_score: usize,
    pressure_score: usize,
    evolution_score: usize,
};

pub extern fn aurora_compute_kernel_profile(
    object_count: c_int,
    capability_count: c_int,
    endpoint_count: c_int,
    region_count: c_int,
    module_count: c_int,
    queued_messages: c_int,
    scheduler_ticks: c_int,
    metrics: [*]c_int,
    metrics_count: c_int,
) void;

pub fn computeKernelProfile(
    object_count: usize,
    capability_count: usize,
    endpoint_count: usize,
    region_count: usize,
    module_count: usize,
    queued_messages: usize,
    scheduler_ticks: usize,
) KernelProfile {
    var metrics = [_]c_int{ 9, 9, 9 };

    aurora_compute_kernel_profile(
        @intCast(object_count),
        @intCast(capability_count),
        @intCast(endpoint_count),
        @intCast(region_count),
        @intCast(module_count),
        @intCast(queued_messages),
        @intCast(scheduler_ticks),
        &metrics,
        metrics.len,
    );

    return .{
        .transparency_score = @intCast(metrics[0]),
        .pressure_score = @intCast(metrics[1]),
        .evolution_score = @intCast(metrics[2]),
    };
}

test "fortran telemetry computes a bounded kernel profile" {
    const profile = computeKernelProfile(5, 2, 1, 3, 1, 2, 4);

    try std.testing.expectEqual(@as(usize, 97), profile.transparency_score);
    try std.testing.expectEqual(@as(usize, 55), profile.pressure_score);
    try std.testing.expectEqual(@as(usize, 71), profile.evolution_score);
}
