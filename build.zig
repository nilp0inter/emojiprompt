const std = @import("std");
const fs = std.fs;
const mem = std.mem;

const Scanner = @import("zig-wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const options = b.addOptions();
    const strip = b.option(bool, "strip", "Omit debug information") orelse false;
    const pie = b.option(bool, "pie", "Build with PIE support (by default false)") orelse false;
    const llvm = !(b.option(bool, "no-llvm", "(expirimental) Use non-LLVM x86 Zig backend") orelse false);

    const scanner = Scanner.create(b, .{});
    scanner.addCustomProtocol("protocol/wlr-layer-shell-unstable-v1.xml");
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml"); // Dependency of layer-shell.
    scanner.addSystemProtocol("staging/cursor-shape/cursor-shape-v1.xml");
    scanner.addSystemProtocol("unstable/tablet/tablet-unstable-v2.xml"); // Dependency of cursor-shape.
    scanner.generate("wp_cursor_shape_manager_v1", 1);
    scanner.generate("wl_compositor", 5);
    scanner.generate("wl_shm", 1);
    scanner.generate("zwlr_layer_shell_v1", 3);
    scanner.generate("wl_seat", 8);
    scanner.generate("wl_output", 4);

    const wayland = b.createModule(.{ .root_source_file = scanner.result });
    const xkbcommon = b.dependency("zig-xkbcommon", .{}).module("xkbcommon");
    const pixman = b.dependency("zig-pixman", .{}).module("pixman");
    const spoon = b.dependency("zig-spoon", .{}).module("spoon");
    const fcft = b.dependency("zig-fcft", .{}).module("fcft");
    const ini = b.dependency("zig-ini", .{}).module("ini");

    const emojiprompt_cli = b.addExecutable(.{
        .name = "emojiprompt",
        .root_source_file = b.path("src/emojiprompt-cli.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .use_llvm = llvm,
        .use_lld = llvm,
    });
    emojiprompt_cli.root_module.addOptions("build_options", options);
    emojiprompt_cli.linkLibC();
    emojiprompt_cli.root_module.addImport("wayland", wayland);
    emojiprompt_cli.linkSystemLibrary("wayland-client");
    emojiprompt_cli.linkSystemLibrary("wayland-cursor");
    scanner.addCSource(emojiprompt_cli);
    emojiprompt_cli.root_module.addImport("ini", ini);
    emojiprompt_cli.root_module.addImport("fcft", fcft);
    emojiprompt_cli.linkSystemLibrary("fcft");
    emojiprompt_cli.root_module.addImport("xkbcommon", xkbcommon);
    emojiprompt_cli.linkSystemLibrary("xkbcommon");
    emojiprompt_cli.root_module.addImport("pixman", pixman);
    emojiprompt_cli.linkSystemLibrary("pixman-1");
    emojiprompt_cli.root_module.addImport("spoon", spoon);
    emojiprompt_cli.root_module.addOptions("build_options", options);
    emojiprompt_cli.pie = pie;
    b.installArtifact(emojiprompt_cli);

    const emojiprompt_pinentry = b.addExecutable(.{
        .name = "pinentry-emojiprompt",
        .root_source_file = b.path("src/emojiprompt-pinentry.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .use_llvm = llvm,
        .use_lld = llvm,
    });
    emojiprompt_pinentry.linkLibC();
    emojiprompt_pinentry.root_module.addImport("wayland", wayland);
    emojiprompt_pinentry.linkSystemLibrary("wayland-client");
    emojiprompt_pinentry.linkSystemLibrary("wayland-cursor");
    scanner.addCSource(emojiprompt_pinentry);
    emojiprompt_pinentry.root_module.addImport("ini", ini);
    emojiprompt_pinentry.root_module.addImport("fcft", fcft);
    emojiprompt_pinentry.linkSystemLibrary("fcft");
    emojiprompt_pinentry.root_module.addImport("xkbcommon", xkbcommon);
    emojiprompt_pinentry.linkSystemLibrary("xkbcommon");
    emojiprompt_pinentry.root_module.addImport("pixman", pixman);
    emojiprompt_pinentry.linkSystemLibrary("pixman-1");
    emojiprompt_pinentry.root_module.addImport("spoon", spoon);
    emojiprompt_pinentry.root_module.addOptions("build_options", options);
    emojiprompt_pinentry.pie = pie;
    b.installArtifact(emojiprompt_pinentry);

    const tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_test = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_test.step);

    b.installFile("bin/emojiprompt-ssh-askpass", "bin/emojiprompt-ssh-askpass");

    b.installFile("doc/emojiprompt.1", "share/man/man1/emojiprompt.1");
    b.installFile("doc/pinentry-emojiprompt.1", "share/man/man1/pinentry-emojiprompt.1");
    b.installFile("doc/emojiprompt-ssh-askpass.1", "share/man/man1/emojiprompt-ssh-askpass.1");
    b.installFile("doc/emojiprompt.5", "share/man/man5/emojiprompt.5");
}
