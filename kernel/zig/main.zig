const std = @import("std");
const capability_mod = @import("core/capability.zig");
const Kernel = @import("core/kernel.zig").Kernel;
const fortran_scheduler = @import("policy/fortran_scheduler.zig");

fn bootstrapScheduler(context: *anyopaque) !void {
    const kernel: *Kernel = @ptrCast(@alignCast(context));
    kernel.noteSchedulerTick(1);
}

fn transparentScheduler(context: *anyopaque) !void {
    const kernel: *Kernel = @ptrCast(@alignCast(context));
    const timeslice = fortran_scheduler.computeTimeslice(kernel.totalQueuedMessages(), 4);
    kernel.noteSchedulerTick(timeslice);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var kernel = try Kernel.init(gpa.allocator(), .{
        .architecture = .host,
    });
    defer kernel.deinit();

    try kernel.addRegion("boot-rom", 0x00000000, 0x000F0000, .{
        .read = true,
    });
    try kernel.addRegion("kernel-text", 0x00100000, 0x00100000, .{
        .read = true,
        .execute = true,
    });
    try kernel.addRegion("live-heap", 0x01000000, 0x01000000, .{
        .read = true,
        .write = true,
    });

    const init_pid = try kernel.createObject(.process, "init", null);
    const shell_pid = try kernel.createObject(.process, "live-shell", init_pid);
    const control_endpoint = try kernel.createObject(.endpoint, "control", init_pid);
    _ = try kernel.createObject(.module, "scheduler", init_pid);
    _ = try kernel.createObject(.capability_space, "init-cspace", init_pid);

    const root_capability = try kernel.mintCapability(init_pid, control_endpoint, capability_mod.Permissions{
        .read = true,
        .write = true,
        .transfer = true,
        .inspect = true,
        .mutate = true,
    });
    _ = try kernel.transferCapability(root_capability.id, shell_pid);

    try kernel.sendMessage(init_pid, control_endpoint, "reload scheduler");
    try kernel.sendMessage(shell_pid, control_endpoint, "dump kernel");

    _ = try kernel.registerModule(.{
        .name = "bootstrap-round-robin",
        .service = .scheduler,
        .version = 1,
        .description = "Minimal scheduler used during bring-up.",
        .handler = bootstrapScheduler,
    });
    try kernel.invokeService(.scheduler);

    _ = try kernel.registerModule(.{
        .name = "transparent-round-robin",
        .service = .scheduler,
        .version = 2,
        .description = "Hot-swapped scheduler that tolerates inspection overhead.",
        .handler = transparentScheduler,
    });
    try kernel.invokeService(.scheduler);

    const stdout = std.io.getStdOut().writer();
    if (kernel.getServiceModule(.scheduler)) |scheduler| {
        try stdout.print("active scheduler: {s} v{}\n", .{ scheduler.name, scheduler.version });
    }
    try stdout.print("scheduler ticks after hot swap: {}\n", .{kernel.scheduler_ticks});
    try stdout.print("queued control messages: {}\n\n", .{kernel.totalQueuedMessages()});
    try kernel.inspect(stdout);

    if (kernel.receiveMessage(control_endpoint)) |message| {
        try stdout.print(
            "\nfirst control message from process {}: {s}\n",
            .{ message.sender_process_id, message.text() },
        );
    }
}

test {
    _ = @import("core/kernel.zig");
    _ = @import("core/capability.zig");
    _ = @import("core/ipc.zig");
    _ = @import("loader/module_loader.zig");
}

test "fortran scheduler computes a contention-aware timeslice" {
    try std.testing.expectEqual(@as(usize, 4), fortran_scheduler.computeTimeslice(1, 4));
    try std.testing.expectEqual(@as(usize, 3), fortran_scheduler.computeTimeslice(2, 4));
    try std.testing.expectEqual(@as(usize, 1), fortran_scheduler.computeTimeslice(8, 4));
}
