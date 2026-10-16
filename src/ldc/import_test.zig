const std = @import("std");
const fixtures = @import("fixtures");
const openwater = @import("../root.zig");
const testing = std.testing;

test "freedom dlf imports to readable uddf" {
    const bytes = fixtures.freedom_mix2_v2_00000007_dlf;
    var owned = try openwater.readDiveComputerDump(testing.allocator, bytes, .{
        .family_name = "freedom",
        .model = 19,
    });
    defer owned.deinit();
    try owned.value.checkReferences(testing.allocator);

    var out = std.Io.Writer.Allocating.init(testing.allocator);
    defer out.deinit();
    try openwater.writeUddf(owned.value, &out.writer);

    try testing.expect(std.mem.indexOf(u8, out.written(), "<uddf version=\"3.2.3\">") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "<greatestdepth>") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "<greatestdepth>18.98</greatestdepth>") != null);

    var roundtrip = try openwater.readUddf(testing.allocator, out.written());
    defer roundtrip.deinit();
    try roundtrip.value.checkReferences(testing.allocator);
}
