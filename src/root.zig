//! OpenWater: a Zig library for UDDF dive plans.
const std = @import("std");

const document_mod = @import("document.zig");
const uddf_mod = @import("uddf.zig");
const json_mod = @import("json.zig");

pub const document = document_mod;

pub const Document = document_mod.Document;
pub const OwnedDocument = document_mod.OwnedDocument;
pub const Generator = document_mod.Generator;
pub const Diver = document_mod.Diver;
pub const Person = document_mod.Person;
pub const Tank = document_mod.Tank;
pub const Geography = document_mod.Geography;
pub const Site = document_mod.Site;
pub const GasLimit = document_mod.GasLimit;
pub const Mix = document_mod.Mix;
pub const SurfaceInterval = document_mod.SurfaceInterval;
pub const InformationBeforeDive = document_mod.InformationBeforeDive;
pub const InformationAfterDive = document_mod.InformationAfterDive;
pub const TankData = document_mod.TankData;
pub const TankPressure = document_mod.TankPressure;
pub const Waypoint = document_mod.Waypoint;
pub const Dive = document_mod.Dive;
pub const RepetitionGroup = document_mod.RepetitionGroup;

pub const readDiveComputerDump = @import("ldc.zig").readDiveComputerDump;
pub const DiveComputerImportOptions = @import("ldc.zig").ImportOptions;

pub const Format = enum {
    uddf_xml,
    dive_json_v1,
    dive_computer_dump,
};

pub const readUddf = uddf_mod.readUddf;
pub const writeUddf = uddf_mod.writeUddf;

pub fn read(
    allocator: std.mem.Allocator,
    format: Format,
    bytes: []const u8,
    dive_computer: DiveComputerImportOptions,
) !OwnedDocument {
    return switch (format) {
        .uddf_xml => readUddf(allocator, bytes),
        .dive_json_v1 => error.UnsupportedFormat,
        .dive_computer_dump => readDiveComputerDump(allocator, bytes, dive_computer),
    };
}

pub fn write(doc: Document, format: Format, writer: *std.Io.Writer) !void {
    switch (format) {
        .uddf_xml => try writeUddf(doc, writer),
        .dive_json_v1 => try json_mod.writeDiveJsonV1(doc, writer),
        .dive_computer_dump => return error.UnsupportedFormat,
    }
}

pub fn convert(
    allocator: std.mem.Allocator,
    from: Format,
    input: []const u8,
    to: Format,
    dive_computer: DiveComputerImportOptions,
    writer: *std.Io.Writer,
) !void {
    var owned = try read(allocator, from, input, dive_computer);
    defer owned.deinit();
    try owned.value.checkReferences(allocator);
    try write(owned.value, to, writer);
}

test {
    _ = @import("json/write_test.zig");
    _ = @import("convert_library_test.zig");
    _ = @import("ldc/import_test.zig");
}
