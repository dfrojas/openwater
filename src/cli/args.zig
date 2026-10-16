const std = @import("std");
const openwater = @import("openwater");

pub const Options = struct {
    input_path: []const u8,
    output_path: []const u8,
    input_format: openwater.Format,
    output_format: openwater.Format,
    dive_computer: openwater.DiveComputerImportOptions,
};

pub fn parse(args: []const []const u8) !Options {
    var input_path: ?[]const u8 = null;
    var output_path: ?[]const u8 = null;
    var family: ?[]const u8 = null;
    var model: ?u32 = null;
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
        } else if (std.mem.eql(u8, flag, "--family")) {
            i += 1;
            if (i >= args.len or args[i].len == 0) return error.InvalidArguments;
            family = args[i];
        } else if (std.mem.eql(u8, flag, "--model")) {
            i += 1;
            if (i >= args.len) return error.InvalidArguments;
            model = try std.fmt.parseInt(u32, args[i], 0);
        } else {
            return error.InvalidArguments;
        }
    }
    const in = input_path orelse return error.InvalidArguments;
    const out = output_path orelse return error.InvalidArguments;
    const input_format = try formatFromPath(in);
    if (input_format == .dive_computer_dump and family == null) return error.MissingDiveComputerFamily;
    return .{
        .input_path = in,
        .output_path = out,
        .input_format = input_format,
        .output_format = try formatFromPath(out),
        .dive_computer = .{
            .family_name = family orelse "",
            .model = model,
        },
    };
}

pub fn formatFromPath(path: []const u8) !openwater.Format {
    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".json")) return .dive_json_v1;
    if (std.mem.eql(u8, ext, ".uddf") or std.mem.eql(u8, ext, ".xml")) return .uddf_xml;
    if (std.mem.eql(u8, ext, ".bin") or std.mem.eql(u8, ext, ".dlf") or std.mem.eql(u8, ext, ".raw")) {
        return .dive_computer_dump;
    }
    return error.UnsupportedFormat;
}
