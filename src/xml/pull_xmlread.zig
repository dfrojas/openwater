const std = @import("std");
const xmlread = @import("xmlread");
const event = @import("event.zig");

const Allocator = std.mem.Allocator;
const pull = xmlread.pull;

pub const Error = error{
    InvalidXml,
    OutOfMemory,
} || pull.Error;

pub const Reader = struct {
    io_reader: std.Io.Reader,
    parser: pull.Parser,
    /// Holds xmlread allocations for every event until `deinit` (Builder may retain slices until dive/site finish).
    events: std.heap.ArenaAllocator,
    pending_end: ?[]const u8 = null,

    pub fn init(gpa: Allocator, source: []const u8) Reader {
        return .{
            .io_reader = std.Io.Reader.fixed(source),
            .parser = pull.Parser.init(gpa),
            .events = std.heap.ArenaAllocator.init(gpa),
            .pending_end = null,
        };
    }

    /// Must run once on the reader's final address before `next` (parser holds `&io_reader`).
    pub fn start(self: *Reader) void {
        self.parser.parse(&self.io_reader);
    }

    pub fn deinit(self: *Reader) void {
        self.parser.deinit();
        self.events.deinit();
    }

    pub fn next(self: *Reader) Error!event.Event {
        if (self.pending_end) |name| {
            self.pending_end = null;
            return .{ .end_element = name };
        }

        const arena = self.events.allocator();

        while (true) {
            const item = self.parser.next(arena) catch |err| switch (err) {
                pull.Error.NotWellFormed => return error.InvalidXml,
                error.Utf8InvalidStartByte,
                error.Utf8ExpectedContinuation,
                error.Utf8OverlongEncoding,
                error.Utf8CodepointTooLarge,
                error.Utf8EncodesSurrogateHalf,
                error.Utf8CannotEncodeSurrogateHalf,
                error.Utf16InvalidStartCodeUnit,
                error.CodepointTooLarge,
                error.ExpectedSecondSurrogateHalf,
                => return error.InvalidXml,
                else => |e| return e,
            };
            const some = item orelse return .eof;

            switch (some) {
                .start_tag => |tag| {
                    if (tag.empty) self.pending_end = tag.name;
                    return .{ .start_element = .{
                        .name = tag.name,
                        .attrs = mapAttrs(tag.attributes),
                    } };
                },
                .end_tag => |tag| return .{ .end_element = tag.name },
                .chardata, .cdata, .char_ref => |text| {
                    const trimmed = std.mem.trim(u8, text, " \t\r\n");
                    if (trimmed.len == 0) continue;
                    return .{ .text = trimmed };
                },
                .xml_decl, .pi, .comment, .doctype => continue,
            }
        }
    }

    fn mapAttrs(attributes: []const pull.Attribute) []const event.Attr {
        return @as([]const event.Attr, @ptrCast(attributes));
    }
};
