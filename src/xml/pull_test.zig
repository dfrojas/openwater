const std = @import("std");
const fixtures = @import("fixtures");
const xml = @import("mod.zig");
const testing = std.testing;

const snippet =
    \\<?xml version="1.0" encoding="UTF-8"?>
    \\<uddf version="3.2.3">
    \\  <generator><name>Spike</name></generator>
    \\</uddf>
;

test "reader skips prolog and yields start tags" {
    var reader = xml.Reader.init(testing.allocator, snippet);
    defer reader.deinit();
    reader.start();

    const e1 = try reader.next();
    try testing.expect(e1 == .start_element);
    try testing.expectEqualStrings("uddf", e1.start_element.name);
    try testing.expectEqual(@as(usize, 1), e1.start_element.attrs.len);
    try testing.expectEqualStrings("version", e1.start_element.attrs[0].name);
    try testing.expectEqualStrings("3.2.3", e1.start_element.attrs[0].value);

    const e2 = try reader.next();
    try testing.expect(e2 == .start_element);
    try testing.expectEqualStrings("generator", e2.start_element.name);

    _ = try reader.next(); // name
    _ = try reader.next(); // text Spike or nested
}

test "fixture first element is uddf" {
    const fixture = fixtures.logbook_v01_uddf;
    var reader = xml.Reader.init(testing.allocator, fixture);
    defer reader.deinit();
    reader.start();
    const first = try reader.next();
    try testing.expect(first == .start_element);
    try testing.expectEqualStrings("uddf", first.start_element.name);
}
