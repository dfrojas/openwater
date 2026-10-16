const std = @import("std");
const args = @import("args.zig");
const openwater = @import("openwater");
const testing = std.testing;

test "parse requires --input and --output" {
    try testing.expectError(error.InvalidArguments, args.parse(&.{}));
    try testing.expectError(error.InvalidArguments, args.parse(&.{ "--input", "a.xml" }));
    try testing.expectError(error.InvalidArguments, args.parse(&.{ "--output", "b.json" }));
}

test "parse maps extensions to formats" {
    const options = try args.parse(&.{ "--input", "plan.uddf.xml", "--output", "dive.json" });
    try testing.expectEqual(openwater.Format.uddf_xml, options.input_format);
    try testing.expectEqual(openwater.Format.dive_json_v1, options.output_format);
    try testing.expectEqualStrings("plan.uddf.xml", options.input_path);
    try testing.expectEqualStrings("dive.json", options.output_path);
}

test "formatFromPath rejects unknown extension" {
    try testing.expectError(error.UnsupportedFormat, args.formatFromPath("notes.txt"));
}

test "parse requires family for vendor dump" {
    try testing.expectError(error.MissingDiveComputerFamily, args.parse(&.{
        "--input",  "dive.dlf",
        "--output", "out.uddf",
    }));
    const options = try args.parse(&.{
        "--input",  "dive.dlf",
        "--output", "out.uddf",
        "--family", "freedom",
    });
    try testing.expectEqual(openwater.Format.dive_computer_dump, options.input_format);
}
