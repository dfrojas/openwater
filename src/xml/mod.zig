//! XML pull boundary for UDDF ingest. Backed by xmlread; not exported from `openwater` root.
const pull = @import("pull_xmlread.zig");

pub const Attr = @import("event.zig").Attr;
pub const Event = @import("event.zig").Event;
pub const StartElement = @import("event.zig").StartElement;
pub const Reader = pull.Reader;
pub const ReadError = pull.Error;

test {
    _ = @import("pull_test.zig");
}
