const std = @import("std");
const args = @import("cli/args.zig");
const convert = @import("cli/convert.zig");

pub fn main(init: std.process.Init) !u8 {
    const slice = try init.minimal.args.toSlice(init.arena.allocator());
    const options = args.parse(slice[1..]) catch {
        std.debug.print(
            "usage: openwater --input <path> --output <path>\n",
            .{},
        );
        return 1;
    };

    convert.run(init.arena.allocator(), init.io, std.Io.Dir.cwd(), options) catch |err| {
        std.debug.print("error: {s}\n", .{@errorName(err)});
        return 1;
    };
    return 0;
}

test {
    _ = @import("cli/args_test.zig");
    _ = @import("cli/convert_cli_test.zig");
}
