const std = @import("std");
const document = @import("../document.zig");

const Envelope = struct {
    schema: []const u8,
    document: document.Document,
};

pub fn writeDiveJsonV1(doc: document.Document, writer: *std.Io.Writer) !void {
    const envelope: Envelope = .{
        .schema = "dive_json_v1",
        .document = doc,
    };
    try std.json.Stringify.value(envelope, .{ .whitespace = .indent_2 }, writer);
}
