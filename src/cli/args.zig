const std = @import("std");
const openwater = @import("openwater");

pub const Options = struct {
    input_path: []const u8,
    output_path: []const u8,
    input_format: openwater.Format,
    output_format: openwater.Format,
};

pub fn parse(args: []const []const u8) !Options {
    var input_path: ?[]const u8 = null;
    var output_path: ?[]const u8 = null;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const flag = args[i];
        if (std.mem.eql(u8, flag, "--input")) {
            i += 1;
            if (i >= args.len or args[i].len == 0) return error.InvalidArguments;
            input_path = args[i];
        } else if (std.mem.eql(u8, flag, "--output")) {
            i += 1;
            if (i >= args.len or args[i].len == 0) return error.InvalidArguments;
            output_path = args[i];
        } else {
            return error.InvalidArguments;
        }
    }
    const in = input_path orelse return error.InvalidArguments;
    const out = output_path orelse return error.InvalidArguments;
    return .{
        .input_path = in,
        .output_path = out,
        .input_format = try formatFromPath(in),
        .output_format = try formatFromPath(out),
    };
}

pub fn formatFromPath(path: []const u8) !openwater.Format {
    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".json")) return .dive_json_v1;
    if (std.mem.eql(u8, ext, ".uddf") or std.mem.eql(u8, ext, ".xml")) return .uddf_xml;
    return error.UnsupportedFormat;
}
