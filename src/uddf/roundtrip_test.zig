const std = @import("std");
const fixtures = @import("fixtures");
const document = @import("../document.zig");
const readUddf = @import("read.zig").readUddf;
const writeUddf = @import("write.zig").writeUddf;
const testing = std.testing;

const fixture = fixtures.logbook_v01_uddf;

test "fixture yields two dives" {
    var owned = try readUddf(testing.allocator, fixture);
    defer owned.deinit();
    const dives = owned.value.groups.?[0].dives;
    try testing.expectEqual(@as(usize, 2), dives.len);
    try testing.expectEqualStrings("dive-1", dives[0].id);
    try testing.expectEqualStrings("dive-2", dives[1].id);
}

test "read fixture, write, read again, equal document" {
    var first = try readUddf(testing.allocator, fixture);
    defer first.deinit();
    try first.value.checkReferences(testing.allocator);

    var out = std.Io.Writer.Allocating.init(testing.allocator);
    defer out.deinit();
    try writeUddf(first.value, &out.writer);

    var second = try readUddf(testing.allocator, out.written());
    defer second.deinit();
    try second.value.checkReferences(testing.allocator);

    try testing.expect(document.Document.eql(first.value, second.value));
}

test "fixture matches expected dive count and summary-only dive" {
    var owned = try readUddf(testing.allocator, fixture);
    defer owned.deinit();
    const doc = owned.value;
    try doc.checkReferences(testing.allocator);
    const dives = doc.groups.?[0].dives;
    try testing.expectEqual(@as(usize, 2), dives.len);
    try testing.expect(dives[1].samples == null);
    try testing.expectEqual(@as(i64, 2700), dives[1].before.surface_interval.?.seconds);
}
