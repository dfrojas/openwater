const std = @import("std");
const document = @import("../document.zig");

const Document = document.Document;

pub fn writeUddf(doc: Document, writer: *std.Io.Writer) !void {
    try writer.print(
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<uddf version="3.2.3">
        \\  <generator>
        \\    <name>{s}</name>
        \\
    ,
        .{doc.generator.name},
    );
    if (doc.generator.version) |version| {
        try writer.print("    <version>{s}</version>\n", .{version});
    }
    try writer.print("  </generator>\n", .{});

    if (doc.diver) |diver| {
        try writer.print("  <diver>\n", .{});
        try writePerson(writer, "owner", diver.owner);
        for (diver.buddies) |buddy| try writePerson(writer, "buddy", buddy);
        try writer.print("  </diver>\n", .{});
    }

    if (doc.sites) |sites| {
        try writer.print("  <divesite>\n", .{});
        for (sites) |site| {
            try writer.print("    <site id=\"{s}\">\n", .{site.id});
            try writer.print("      <name>{s}</name>\n", .{site.name});
            if (site.geography) |geo| {
                try writer.print("      <geography>\n", .{});
                try writer.print("        <location>{s}</location>\n", .{geo.location});
                if (geo.latitude_deg) |v| try writer.print("        <latitude>{d}</latitude>\n", .{v});
                if (geo.longitude_deg) |v| try writer.print("        <longitude>{d}</longitude>\n", .{v});
                if (geo.altitude_m) |v| try writer.print("        <altitude>{d}</altitude>\n", .{v});
                try writer.print("      </geography>\n", .{});
            }
            try writer.print("    </site>\n", .{});
        }
        try writer.print("  </divesite>\n", .{});
    }

    if (doc.mixes) |mixes| {
        try writer.print("  <gasdefinitions>\n", .{});
        for (mixes) |mix| {
            try writer.print("    <mix id=\"{s}\">\n", .{mix.id});
            try writer.print("      <name>{s}</name>\n", .{mix.name});
            if (mix.o2) |v| try writer.print("      <o2>{d}</o2>\n", .{v});
            if (mix.n2) |v| try writer.print("      <n2>{d}</n2>\n", .{v});
            if (mix.he) |v| try writer.print("      <he>{d}</he>\n", .{v});
            if (mix.ar) |v| try writer.print("      <ar>{d}</ar>\n", .{v});
            if (mix.h2) |v| try writer.print("      <h2>{d}</h2>\n", .{v});
            if (mix.limit) |limit| switch (limit) {
                .maximum_po2_pa => |v| try writer.print("      <maximumpo2>{d}</maximumpo2>\n", .{v}),
                .maximum_depth_m => |v| try writer.print("      <maximumoperationdepth>{d}</maximumoperationdepth>\n", .{v}),
            };
            try writer.print("    </mix>\n", .{});
        }
        try writer.print("  </gasdefinitions>\n", .{});
    }

    if (doc.groups) |groups| {
        try writer.print("  <profiledata>\n", .{});
        for (groups) |group| {
            try writer.print("    <repetitiongroup id=\"{s}\">\n", .{group.id});
            for (group.dives) |dive| try writeDive(writer, dive);
            try writer.print("    </repetitiongroup>\n", .{});
        }
        try writer.print("  </profiledata>\n", .{});
    }

    try writer.print("</uddf>\n", .{});
    try writer.flush();
}

fn writePerson(writer: *std.Io.Writer, tag: []const u8, person: document.Person) !void {
    try writer.print("    <{s} id=\"{s}\">\n", .{ tag, person.id });
    try writer.print("      <personal>\n", .{});
    try writer.print("        <firstname>{s}</firstname>\n", .{person.first_name});
    try writer.print("        <lastname>{s}</lastname>\n", .{person.last_name});
    try writer.print("      </personal>\n", .{});
    if (person.tanks.len > 0) {
        try writer.print("      <equipment>\n", .{});
        for (person.tanks) |tank| {
            try writer.print("        <tank id=\"{s}\">\n", .{tank.id});
            try writer.print("          <name>{s}</name>\n", .{tank.name});
            if (tank.volume_m3) |v| try writer.print("          <tankvolume>{d}</tankvolume>\n", .{v});
            try writer.print("        </tank>\n", .{});
        }
        try writer.print("      </equipment>\n", .{});
    }
    try writer.print("    </{s}>\n", .{tag});
}

fn writeDive(writer: *std.Io.Writer, dive: document.Dive) !void {
    try writer.print("      <dive id=\"{s}\">\n", .{dive.id});
    try writer.print("        <informationbeforedive>\n", .{});
    for (dive.before.links) |link| try writer.print("          <link ref=\"{s}\"/>\n", .{link});
    try writer.print("          <datetime>{s}</datetime>\n", .{dive.before.datetime});
    if (dive.before.dive_number) |n| try writer.print("          <divenumber>{d}</divenumber>\n", .{n});
    if (dive.before.surface_interval) |interval| {
        try writer.print("          <surfaceintervalbeforedive>\n", .{});
        switch (interval) {
            .infinity => try writer.print("            <infinity/>\n", .{}),
            .seconds => |s| try writer.print("            <passedtime>{d}.0</passedtime>\n", .{s}),
        }
        try writer.print("          </surfaceintervalbeforedive>\n", .{});
    }
    if (dive.before.surface_pressure_pa) |v| try writer.print("          <surfacepressure>{d}</surfacepressure>\n", .{v});
    try writer.print("        </informationbeforedive>\n", .{});

    for (dive.tanks) |tank| {
        try writer.print("        <tankdata>\n", .{});
        for (tank.links) |link| try writer.print("          <link ref=\"{s}\"/>\n", .{link});
        if (tank.volume_m3) |v| try writer.print("          <tankvolume>{d}</tankvolume>\n", .{v});
        try writer.print("          <tankpressurebegin>{d}</tankpressurebegin>\n", .{tank.pressure_begin_pa});
        if (tank.pressure_end_pa) |v| try writer.print("          <tankpressureend>{d}</tankpressureend>\n", .{v});
        try writer.print("        </tankdata>\n", .{});
    }

    if (dive.samples) |samples| {
        try writer.print("        <samples>\n", .{});
        for (samples) |sample| {
            try writer.print("          <waypoint>\n", .{});
            if (sample.depth_m) |v| try writer.print("            <depth>{d}</depth>\n", .{v});
            if (sample.time_s) |v| try writer.print("            <divetime>{d}</divetime>\n", .{v});
            if (sample.switch_mix_ref) |ref| try writer.print("            <switchmix ref=\"{s}\"/>\n", .{ref});
            for (sample.pressures) |pressure| {
                if (pressure.tank_ref) |ref| {
                    try writer.print("            <tankpressure tankref=\"{s}\">{d}</tankpressure>\n", .{ ref, pressure.pressure_pa });
                } else {
                    try writer.print("            <tankpressure>{d}</tankpressure>\n", .{pressure.pressure_pa});
                }
            }
            if (sample.temperature_k) |v| try writer.print("            <temperature>{d}</temperature>\n", .{v});
            if (sample.heart_rate_per_s) |v| try writer.print("            <heartrate>{d}</heartrate>\n", .{v});
            try writer.print("          </waypoint>\n", .{});
        }
        try writer.print("        </samples>\n", .{});
    }

    try writer.print("        <informationafterdive>\n", .{});
    try writer.print("          <greatestdepth>{d}</greatestdepth>\n", .{dive.after.greatest_depth_m});
    try writer.print("          <diveduration>{d}</diveduration>\n", .{dive.after.duration_s});
    if (dive.after.lowest_temperature_k) |v| try writer.print("          <lowesttemperature>{d}</lowesttemperature>\n", .{v});
    try writer.print("        </informationafterdive>\n", .{});
    try writer.print("      </dive>\n", .{});
}
