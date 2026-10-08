const std = @import("std");

pub fn main(init: std.process.Init) !u8 {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var buffer: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    inspect(init.io, args[1..], &stdout.interface) catch |err| {
        if (err == error.InvalidArguments) {
            std.debug.print("error: expected inspect <path>\nusage: openwater inspect <path>\n", .{});
        } else {
            std.debug.print("error: inspect '{s}': {s}\n", .{ args[2], @errorName(err) });
        }
        return 1;
    };
    return 0;
}

fn inspect(io: std.Io, args: []const []const u8, output: *std.Io.Writer) !void {
    if (args.len != 2 or !std.mem.eql(u8, args[0], "inspect") or args[1].len == 0)
        return error.InvalidArguments;

    const file = try std.Io.Dir.cwd().openFile(io, args[1], .{ .allow_directory = false });
    defer file.close(io);
    const stat = try file.stat(io);
    try output.print("Path: {s}\nSize: {d} bytes\n", .{ args[1], stat.size });
    try output.flush();
}

test "inspect reports the supplied path and byte size" {
    const testing = std.testing;
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "dive plan", .data = "dive\n" });
    const path = try tmp.dir.realPathFileAlloc(io, "dive plan", testing.allocator);
    defer testing.allocator.free(path);

    var buffer: [8192]u8 = undefined;
    var output = std.Io.Writer.fixed(&buffer);
    try inspect(io, &.{ "inspect", path }, &output);
    const expected = try std.fmt.allocPrint(testing.allocator, "Path: {s}\nSize: 5 bytes\n", .{path});
    defer testing.allocator.free(expected);
    try testing.expectEqualStrings(expected, output.buffered());
}

test "inspect rejects invalid arguments and inaccessible files" {
    const testing = std.testing;
    const io = testing.io;
    var output = std.Io.Writer.fixed(&.{});
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();
    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", testing.allocator);
    defer testing.allocator.free(dir_path);
    const path = try std.fs.path.join(testing.allocator, &.{ dir_path, "missing" });
    defer testing.allocator.free(path);

    try testing.expectError(error.InvalidArguments, inspect(io, &.{}, &output));
    try testing.expectError(error.InvalidArguments, inspect(io, &.{"inspect"}, &output));
    try testing.expectError(error.InvalidArguments, inspect(io, &.{ "other", path }, &output));
    try testing.expectError(error.InvalidArguments, inspect(io, &.{ "inspect", path, "extra" }, &output));
    try testing.expectError(error.InvalidArguments, inspect(io, &.{ "inspect", "" }, &output));
    try testing.expectError(error.IsDir, inspect(io, &.{ "inspect", dir_path }, &output));
    try testing.expectError(error.FileNotFound, inspect(io, &.{ "inspect", path }, &output));
}
