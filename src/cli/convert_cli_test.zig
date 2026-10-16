const std = @import("std");
const args = @import("args.zig");
const convert = @import("convert.zig");
const fixtures = @import("fixtures");
const testing = std.testing;

const fixture = fixtures.logbook_v01_uddf;

test "convert writes json output file" {
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "plan.uddf.xml", .data = fixture });

    const options = args.Options{
        .input_path = "plan.uddf.xml",
        .output_path = "dive.json",
        .input_format = .uddf_xml,
        .output_format = .dive_json_v1,
        .dive_computer = .{ .family_name = "" },
    };
    try convert.run(testing.allocator, io, tmp.dir, options);

    const written = try tmp.dir.readFileAlloc(io, "dive.json", testing.allocator, .unlimited);
    defer testing.allocator.free(written);
    try testing.expect(std.mem.indexOf(u8, written, "dive_json_v1") != null);
}
