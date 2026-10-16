const std = @import("std");
const fixtures = @import("fixtures");
const openwater = @import("root.zig");
const testing = std.testing;

test "convert uddf_xml to dive_json_v1 runs checkReferences" {
    var out = std.Io.Writer.Allocating.init(testing.allocator);
    defer out.deinit();
    const unused_dc = openwater.DiveComputerImportOptions{ .family_name = "" };
    try openwater.convert(testing.allocator, .uddf_xml, fixtures.logbook_v01_uddf, .dive_json_v1, unused_dc, &out.writer);
    try testing.expect(out.written().len > 0);
    try testing.expect(std.mem.indexOf(u8, out.written(), "\"schema\": \"dive_json_v1\"") != null);
}
