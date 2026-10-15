pub const Attr = struct { name: []const u8, value: []const u8 };

pub const StartElement = struct { name: []const u8, attrs: []const Attr };

pub const Event = union(enum) {
    start_element: StartElement,
    end_element: []const u8,
    text: []const u8,
    eof,
};
