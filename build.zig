const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const fortran_objects = [_]std.Build.LazyPath{
        addFortranObject(b, "kernel/fortran/scheduler/round_robin.f90", "round_robin.o"),
        addFortranObject(b, "kernel/fortran/capability/policy.f90", "capability_policy.o"),
        addFortranObject(b, "kernel/fortran/transparency/telemetry.f90", "telemetry.o"),
        addFortranObject(b, "runtime/fortran_min/aurora_runtime.f90", "aurora_runtime.o"),
    };

    const exe = b.addExecutable(.{
        .name = "aurora-prototype",
        .root_source_file = b.path("kernel/zig/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    for (fortran_objects) |object_file| {
        exe.addObjectFile(object_file);
    }

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
    unit_tests.linkLibC();
    for (fortran_objects) |object_file| {
        unit_tests.addObjectFile(object_file);
    }

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
