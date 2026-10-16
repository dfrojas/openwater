const std = @import("std");
const fixtures = @import("fixtures");
const openwater = @import("../root.zig");
const testing = std.testing;

const fixture = fixtures.logbook_v01_uddf;

test "dive_json_v1 mirrors document generator and dive count" {
    const unused_dc = openwater.DiveComputerImportOptions{ .family_name = "" };
    var owned = try openwater.read(testing.allocator, .uddf_xml, fixture, unused_dc);
    defer owned.deinit();
    try owned.value.checkReferences(testing.allocator);

    var out = std.Io.Writer.Allocating.init(testing.allocator);
    defer out.deinit();
    try openwater.write(owned.value, .dive_json_v1, &out.writer);

    const json = out.written();
    try testing.expect(std.mem.indexOf(u8, json, "\"schema\": \"dive_json_v1\"") != null);
    try testing.expect(std.mem.indexOf(u8, json, "\"name\": \"OpenWater spike\"") != null);

    var parsed = try std.json.parseFromSlice(std.json.Value, testing.allocator, json, .{});
    defer parsed.deinit();
    const dives = parsed.value.object.get("document").?.object.get("groups").?.array.items[0].object.get("dives").?.array;
    try testing.expectEqual(@as(usize, 2), dives.items.len);
}
