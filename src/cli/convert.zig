const std = @import("std");
const openwater = @import("openwater");
const args = @import("args.zig");

pub fn run(gpa: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, options: args.Options) !void {
    const input = try dir.readFileAlloc(io, options.input_path, gpa, .unlimited);
    defer gpa.free(input);

    var out = std.Io.Writer.Allocating.init(gpa);
    defer out.deinit();
    try openwater.convert(gpa, options.input_format, input, options.output_format, options.dive_computer, &out.writer);

    try dir.writeFile(io, .{
        .sub_path = options.output_path,
        .data = out.written(),
    });
}
