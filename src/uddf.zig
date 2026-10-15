const read_mod = @import("uddf/read.zig");
const write_mod = @import("uddf/write.zig");

pub const readUddf = read_mod.readUddf;
pub const writeUddf = write_mod.writeUddf;

test {
    _ = @import("uddf/roundtrip_test.zig");
}
