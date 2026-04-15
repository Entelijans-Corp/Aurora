const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const scheduler_obj = addFortranObject(
        b,
        "kernel/fortran/scheduler/round_robin.f90",
        "round_robin.o",
    );

    const exe = b.addExecutable(.{
        .name = "aurora-prototype",
        .root_source_file = b.path("kernel/zig/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.addObjectFile(scheduler_obj);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the Aurora kernel prototype");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("kernel/zig/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addObjectFile(scheduler_obj);

    const run_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run Aurora prototype tests");
    test_step.dependOn(&run_tests.step);
}

fn addFortranObject(b: *std.Build, source_path: []const u8, output_name: []const u8) std.Build.LazyPath {
    const compile = b.addSystemCommand(&.{ "gfortran", "-c" });
    compile.addFileArg(b.path(source_path));
    compile.addArg("-o");
    return compile.addOutputFileArg(output_name);
}
