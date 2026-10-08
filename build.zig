const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const openwater = b.addModule("openwater", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "openwater",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "openwater", .module = openwater }},
        }),
    });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    b.step("run", "Run the CLI/dev harness").dependOn(&run.step);

    const test_step = b.step("test", "Run library and CLI tests");
    const library_tests = b.addTest(.{ .root_module = openwater });
    const cli_tests = b.addTest(.{ .root_module = exe.root_module });
    test_step.dependOn(&b.addRunArtifact(library_tests).step);
    test_step.dependOn(&b.addRunArtifact(cli_tests).step);
}
