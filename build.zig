const std = @import("std");
const libdivecomputer_build = @import("libdivecomputer_build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const xmlread = b.dependency("xmlread", .{
        .target = target,
        .optimize = optimize,
    });

    const ldc_dep = b.dependency("libdivecomputer", .{
        .target = target,
        .optimize = optimize,
    });
    const ldc_root = ldc_dep.path("");
    const ldc_lib = libdivecomputer_build.addStaticLibrary(b, ldc_root, target, optimize);

    const ldc_translate = b.addTranslateC(.{
        .root_source_file = b.path("src/ldc/libdivecomputer.h"),
        .target = target,
        .optimize = optimize,
    });
    ldc_translate.addAfterIncludePath(b.path("vendor/libdivecomputer"));
    ldc_translate.addAfterIncludePath(ldc_root.path(b, "include"));
    const ldc_c = ldc_translate.createModule();

    const fixtures = b.addModule("fixtures", .{
        .root_source_file = b.path("fixtures/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const openwater = b.addModule("openwater", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    openwater.addImport("xmlread", xmlread.module("xml"));
    openwater.addImport("fixtures", fixtures);
    openwater.addImport("ldc_c", ldc_c);
    openwater.linkLibrary(ldc_lib);

    const exe = b.addExecutable(.{
        .name = "openwater",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "openwater", .module = openwater },
                .{ .name = "fixtures", .module = fixtures },
            },
        }),
    });
    exe.root_module.linkLibrary(ldc_lib);
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    b.step("run", "Run the CLI/dev harness").dependOn(&run.step);

    const test_step = b.step("test", "Run library and CLI tests");
    const library_tests = b.addTest(.{ .root_module = openwater });
    library_tests.root_module.linkLibrary(ldc_lib);
    const cli_tests = b.addTest(.{ .root_module = exe.root_module });
    cli_tests.root_module.linkLibrary(ldc_lib);
    test_step.dependOn(&b.addRunArtifact(library_tests).step);
    test_step.dependOn(&b.addRunArtifact(cli_tests).step);
}
