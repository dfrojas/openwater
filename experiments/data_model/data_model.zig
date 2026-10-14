//! Experimental UDDF 3.2.3 subset. See DATA_MODEL.md; not a public API.
const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const Generator = struct { name: []const u8, version: ?[]const u8 = null };

const Diver = struct { owner: Person, buddies: []const Person = &.{} };

const Person = struct {
    id: []const u8,
    first_name: []const u8,
    last_name: []const u8,
    tanks: []const Tank = &.{},
};

const Tank = struct {
    id: []const u8,
    name: []const u8,
    volume_m3: ?f32 = null,
};

const Geography = struct {
    location: []const u8,
    latitude_deg: ?f32 = null,
    longitude_deg: ?f32 = null,
    altitude_m: ?f32 = null,
};

const Site = struct { id: []const u8, name: []const u8, geography: ?Geography = null };

const Mix = struct {
    id: []const u8,
    name: []const u8,
    o2: ?f32 = null,
    n2: ?f32 = null,
    he: ?f32 = null,
    ar: ?f32 = null,
    h2: ?f32 = null,
    limit: ?union(enum) { maximum_po2_pa: f32, maximum_depth_m: f32 } = null,
};

const SurfaceInterval = union(enum) { infinity, seconds: i64 };

const InformationBeforeDive = struct {
    links: []const []const u8 = &.{},
    datetime: []const u8,
    dive_number: ?u32 = null,
    surface_interval: ?SurfaceInterval = null,
    surface_pressure_pa: ?f32 = null,
};

const InformationAfterDive = struct {
    greatest_depth_m: f32,
    duration_s: f32,
    lowest_temperature_k: ?f32 = null,
};

const TankData = struct {
    // XSD tankdata has no ID. Links identify equipment tanks and gas mixes.
    links: []const []const u8 = &.{},
    volume_m3: ?f32 = null,
    pressure_begin_pa: f32,
    pressure_end_pa: ?f32 = null,
};

const TankPressure = struct { tank_ref: ?[]const u8 = null, pressure_pa: f32 };

const Waypoint = struct {
    depth_m: ?f32 = null,
    time_s: ?f32 = null,
    switch_mix_ref: ?[]const u8 = null,
    pressures: []const TankPressure = &.{},
    temperature_k: ?f32 = null,
    heart_rate_per_s: ?f32 = null,
};

const Dive = struct {
    id: []const u8,
    before: InformationBeforeDive,
    tanks: []const TankData = &.{},
    samples: ?[]const Waypoint = null,
    after: InformationAfterDive,
};

const RepetitionGroup = struct { id: []const u8, dives: []const Dive };

const Kind = enum { owner, buddy, tank, site, mix, group, dive };

const Ids = std.StringHashMap(Kind);

const Document = struct {
    generator: Generator,
    diver: ?Diver = null,
    sites: ?[]const Site = null,
    mixes: ?[]const Mix = null,
    groups: ?[]const RepetitionGroup = null,

    /// Checks identity and reference targets only; independent of ownership.
    fn checkReferences(self: Document, allocator: Allocator) !void {
        var ids = Ids.init(allocator);
        defer ids.deinit();
        // Collect first: IDREFs can point forward and IDs share one namespace.
        if (self.diver) |diver| {
            try addPerson(&ids, diver.owner, .owner);
            for (diver.buddies) |buddy| try addPerson(&ids, buddy, .buddy);
        }
        if (self.sites) |sites| for (sites) |site| try addId(&ids, site.id, .site);
        if (self.mixes) |mixes| for (mixes) |mix| try addId(&ids, mix.id, .mix);
        if (self.groups) |groups| {
            for (groups) |group| {
                try addId(&ids, group.id, .group);
                for (group.dives) |dive| try addId(&ids, dive.id, .dive);
            }
            for (groups) |group| for (group.dives) |dive| {
                for (dive.before.links) |ref| try checkRef(&ids, ref, &.{ .buddy, .site });
                for (dive.tanks) |tank| {
                    for (tank.links) |ref| try checkRef(&ids, ref, &.{ .tank, .mix });
                }
                if (dive.samples) |samples| {
                    for (samples) |sample| {
                        if (sample.switch_mix_ref) |ref| try checkRef(&ids, ref, &.{.mix});
                        for (sample.pressures) |pressure| {
                            if (pressure.tank_ref) |ref| try checkRef(&ids, ref, &.{.tank});
                        }
                    }
                }
            };
        }
    }

    fn findMix(self: Document, id: []const u8) ?*const Mix {
        // ponytail: linear lookup for the spike; add an index if measured use needs it.
        for (self.mixes orelse return null) |*mix| {
            if (std.mem.eql(u8, mix.id, id)) return mix;
        }
        return null;
    }
};

fn addId(ids: *Ids, id: []const u8, kind: Kind) !void {
    if (id.len == 0) return error.EmptyId;
    const entry = try ids.getOrPut(id);
    if (entry.found_existing) return error.DuplicateId;
    entry.value_ptr.* = kind;
}

fn addPerson(ids: *Ids, person: Person, kind: Kind) !void {
    try addId(ids, person.id, kind);
    for (person.tanks) |tank| try addId(ids, tank.id, .tank);
}

fn checkRef(ids: *const Ids, ref: []const u8, allowed: []const Kind) !void {
    const kind = ids.get(ref) orelse return error.UnresolvedReference;
    for (allowed) |candidate| if (candidate == kind) return;
    return error.WrongReferenceKind;
}

const OwnedDocument = struct {
    arena: std.heap.ArenaAllocator,
    value: Document,

    /// Deep copy only. The source can be released after success.
    fn init(allocator: Allocator, source: Document) !OwnedDocument {
        var arena = std.heap.ArenaAllocator.init(allocator);
        errdefer arena.deinit();
        const a = arena.allocator();
        var value = source;
        value.generator.name = try a.dupe(u8, source.generator.name);
        value.generator.version = try copyOptional(a, source.generator.version);
        if (source.diver) |diver| {
            const buddies = try a.dupe(Person, diver.buddies);
            for (buddies) |*buddy| buddy.* = try copyPerson(a, buddy.*);
            value.diver = .{ .owner = try copyPerson(a, diver.owner), .buddies = buddies };
        }
        if (source.sites) |sites| {
            const copies = try a.dupe(Site, sites);
            for (copies) |*site| {
                site.id = try a.dupe(u8, site.id);
                site.name = try a.dupe(u8, site.name);
                if (site.geography) |*geo| geo.location = try a.dupe(u8, geo.location);
            }
            value.sites = copies;
        }
        if (source.mixes) |mixes| {
            const copies = try a.dupe(Mix, mixes);
            for (copies) |*mix| {
                mix.id = try a.dupe(u8, mix.id);
                mix.name = try a.dupe(u8, mix.name);
            }
            value.mixes = copies;
        }
        if (source.groups) |groups| {
            const copies = try a.dupe(RepetitionGroup, groups);
            for (copies) |*group| {
                group.id = try a.dupe(u8, group.id);
                const dives = try a.dupe(Dive, group.dives);
                group.dives = dives;
                for (dives) |*dive| {
                    dive.id = try a.dupe(u8, dive.id);
                    dive.before.datetime = try a.dupe(u8, dive.before.datetime);
                    dive.before.links = try copyLinks(a, dive.before.links);
                    const tanks = try a.dupe(TankData, dive.tanks);
                    dive.tanks = tanks;
                    for (tanks) |*tank| tank.links = try copyLinks(a, tank.links);
                    if (dive.samples) |samples| {
                        const waypoints = try a.dupe(Waypoint, samples);
                        dive.samples = waypoints;
                        for (waypoints) |*waypoint| {
                            waypoint.switch_mix_ref = try copyOptional(a, waypoint.switch_mix_ref);
                            const pressures = try a.dupe(TankPressure, waypoint.pressures);
                            waypoint.pressures = pressures;
                            for (pressures) |*pressure| pressure.tank_ref = try copyOptional(a, pressure.tank_ref);
                        }
                    }
                }
            }
            value.groups = copies;
        }
        // Never store `a`: it points at the local arena, which moves on return.
        return .{ .arena = arena, .value = value };
    }

    fn deinit(self: *OwnedDocument) void {
        self.arena.deinit();
        self.* = undefined;
    }
};

fn copyOptional(a: Allocator, text: ?[]const u8) !?[]const u8 {
    return if (text) |value| try a.dupe(u8, value) else null;
}

fn copyLinks(a: Allocator, links: []const []const u8) ![]const []const u8 {
    const result = try a.dupe([]const u8, links);
    for (result) |*link| link.* = try a.dupe(u8, link.*);
    return result;
}

fn copyPerson(a: Allocator, source: Person) !Person {
    var person = source;
    person.id = try a.dupe(u8, source.id);
    person.first_name = try a.dupe(u8, source.first_name);
    person.last_name = try a.dupe(u8, source.last_name);
    const tanks = try a.dupe(Tank, source.tanks);
    person.tanks = tanks;
    for (tanks) |*tank| {
        tank.id = try a.dupe(u8, tank.id);
        tank.name = try a.dupe(u8, tank.name);
    }
    return person;
}

// Synthetic recorded dives, not decompression advice or a dive plan.
const example: Document = .{
    .generator = .{ .name = "OpenWater spike", .version = "experiment" },
    .diver = .{
        .owner = .{ .id = "owner", .first_name = "Ada", .last_name = "Diver", .tanks = &.{
            .{ .id = "back", .name = "Back gas", .volume_m3 = 0.012 },
            .{ .id = "stage", .name = "Stage", .volume_m3 = 0.007 },
        } },
        .buddies = &.{.{ .id = "buddy", .first_name = "Sam", .last_name = "Diver" }},
    },
    .sites = &.{.{ .id = "reef", .name = "Reef", .geography = .{
        .location = "Example bay",
        .latitude_deg = 28.5,
        .longitude_deg = -16.3,
        .altitude_m = 0,
    } }},
    .mixes = &.{
        .{ .id = "air", .name = "Air", .o2 = 0.21, .n2 = 0.79, .he = 0, .ar = 0, .h2 = 0 },
        .{ .id = "ean50", .name = "EAN50", .o2 = 0.5, .n2 = 0.5, .limit = .{ .maximum_po2_pa = 160000 } },
    },
    .groups = &.{.{ .id = "day-1", .dives = &.{
        .{
            .id = "dive-1",
            .before = .{ .links = &.{ "reef", "buddy" }, .datetime = "2026-10-08T10:00:00Z", .dive_number = 10, .surface_interval = .infinity },
            .tanks = &.{
                .{ .links = &.{ "back", "air" }, .pressure_begin_pa = 20000000, .pressure_end_pa = 12000000 },
                .{ .links = &.{ "stage", "ean50" }, .pressure_begin_pa = 20000000 },
            },
            .samples = &.{
                .{ .depth_m = 0, .time_s = 0, .switch_mix_ref = "air", .pressures = &.{
                    .{ .tank_ref = "back", .pressure_pa = 20000000 },
                    .{ .tank_ref = "stage", .pressure_pa = 20000000 },
                }, .temperature_k = 293.15, .heart_rate_per_s = 1.2 },
                .{ .depth_m = 20, .time_s = 120 },
                .{ .depth_m = 5, .time_s = 600, .switch_mix_ref = "ean50" },
                .{ .depth_m = 0, .time_s = 900 },
            },
            .after = .{ .greatest_depth_m = 20, .duration_s = 900, .lowest_temperature_k = 290.15 },
        },
        .{
            .id = "dive-2",
            .before = .{ .links = &.{"reef"}, .datetime = "2026-10-08T12:00:00+01:00", .surface_interval = .{ .seconds = 2700 } },
            .after = .{ .greatest_depth_m = 10, .duration_s = 720 },
        },
    } }},
};

fn exerciseOwned(allocator: Allocator) !void {
    var owned = try OwnedDocument.init(allocator, example);
    defer owned.deinit();
    const doc = owned.value;
    try doc.checkReferences(allocator);
    const dives = doc.groups.?[0].dives;
    try testing.expectEqual(@as(usize, 2), dives.len);
    try testing.expectEqual(@as(i64, 2700), dives[1].before.surface_interval.?.seconds);
    try testing.expect(dives[1].samples == null);
    try testing.expectEqualStrings("reef", dives[0].before.links[0]);
    const samples = dives[0].samples.?;
    try testing.expectEqual(@as(usize, 2), samples[0].pressures.len);
    var active: ?*const Mix = null;
    for (samples) |sample| if (sample.switch_mix_ref) |ref| {
        active = doc.findMix(ref);
        try testing.expect(active != null);
    };
    try testing.expectEqualStrings("ean50", active.?.id);
    try testing.expectEqual(@as(f32, 0.5), active.?.o2.?);
    try testing.expect(doc.findMix("missing") == null);
    // Deep-copy evidence at several levels, including nested reference strings.
    try testing.expect(doc.generator.name.ptr != example.generator.name.ptr);
    try testing.expect(doc.diver.?.owner.tanks.ptr != example.diver.?.owner.tanks.ptr);
    try testing.expect(dives.ptr != example.groups.?[0].dives.ptr);
    try testing.expect(samples.ptr != example.groups.?[0].dives[0].samples.?.ptr);
    try testing.expect(samples[0].pressures.ptr != example.groups.?[0].dives[0].samples.?[0].pressures.ptr);
    try testing.expect(samples[0].pressures[0].tank_ref.?.ptr != example.groups.?[0].dives[0].samples.?[0].pressures[0].tank_ref.?.ptr);
}

test "owned representative logbook: relationships, access, and cleanup" {
    try exerciseOwned(testing.allocator);
}

test "source storage can be freed before the owned document" {
    var owned = blk: {
        var source = try OwnedDocument.init(testing.allocator, example);
        defer source.deinit();
        break :blk try OwnedDocument.init(testing.allocator, source.value);
    };
    defer owned.deinit();
    try testing.expectEqualStrings("OpenWater spike", owned.value.generator.name);
    try testing.expectEqualStrings("experiment", owned.value.generator.version.?);
    try testing.expectEqualStrings("Ada", owned.value.diver.?.owner.first_name);
    try testing.expectEqualStrings("Diver", owned.value.diver.?.buddies[0].last_name);
    try testing.expectEqualStrings("Back gas", owned.value.diver.?.owner.tanks[0].name);
    try testing.expectEqualStrings("Example bay", owned.value.sites.?[0].geography.?.location);
    try testing.expectEqualStrings("EAN50", owned.value.findMix("ean50").?.name);
    try owned.value.checkReferences(testing.allocator);
}

test "every backing allocation failure is propagated and cleaned up" {
    try testing.checkAllAllocationFailures(testing.allocator, exerciseOwned, .{});
}

fn exerciseDuplicateIds(allocator: Allocator) !void {
    var source = example;
    var sites = [_]Site{example.sites.?[0]};
    sites[0].id = "air"; // Collision across entity kinds, detected after copying.
    source.sites = &sites;
    var owned = try OwnedDocument.init(allocator, source);
    defer owned.deinit();
    owned.value.checkReferences(allocator) catch |err| switch (err) {
        error.DuplicateId => return,
        else => return err,
    };
    return error.ExpectedDuplicateId;
}

test "construction permits duplicate IDs; separate identity check and cleanup" {
    try testing.checkAllAllocationFailures(testing.allocator, exerciseDuplicateIds, .{});
}

test "references reject absent targets and incorrect target kinds" {
    var doc = example;
    var dive = example.groups.?[0].dives[0];
    var group = RepetitionGroup{ .id = "group", .dives = (&dive)[0..1] };
    doc.groups = (&group)[0..1];
    dive.before.links = &.{"absent"};
    try testing.expectError(error.UnresolvedReference, doc.checkReferences(testing.allocator));
    dive.before.links = &.{"air"};
    try testing.expectError(error.WrongReferenceKind, doc.checkReferences(testing.allocator));
    dive.before.links = &.{"buddy"};
    var sample = Waypoint{ .switch_mix_ref = "reef" };
    dive.samples = (&sample)[0..1];
    try testing.expectError(error.WrongReferenceKind, doc.checkReferences(testing.allocator));
    sample.switch_mix_ref = "air";
    sample.pressures = &.{.{ .tank_ref = "air", .pressure_pa = 10000000 }};
    try testing.expectError(error.WrongReferenceKind, doc.checkReferences(testing.allocator));
    sample.pressures = &.{.{ .pressure_pa = 10000000 }}; // No tank association invented.
    try doc.checkReferences(testing.allocator);
    dive.tanks = &.{.{ .links = &.{"reef"}, .pressure_begin_pa = 10000000 }};
    try testing.expectError(error.WrongReferenceKind, doc.checkReferences(testing.allocator));
    group.id = "";
    try testing.expectError(error.EmptyId, doc.checkReferences(testing.allocator));
}

test "owned copies preserve absent, empty, and sparse samples" {
    var doc = example;
    var dives = [_]Dive{
        example.groups.?[0].dives[1],
        example.groups.?[0].dives[1],
        example.groups.?[0].dives[1],
    };
    dives[1].id = "empty";
    dives[1].samples = &.{};
    dives[2].id = "sparse";
    dives[2].samples = &.{.{}};
    const group = RepetitionGroup{ .id = "group", .dives = &dives };
    doc.groups = (&group)[0..1];
    doc.sites = &.{};
    doc.mixes = null;
    var owned = try OwnedDocument.init(testing.allocator, doc);
    defer owned.deinit();
    const copies = owned.value.groups.?[0].dives;
    try testing.expect(owned.value.mixes == null);
    try testing.expectEqual(@as(usize, 0), owned.value.sites.?.len);
    try testing.expect(copies[0].samples == null);
    try testing.expectEqual(@as(usize, 0), copies[1].samples.?.len);
    try testing.expectEqual(@as(usize, 1), copies[2].samples.?.len);
    try testing.expect(copies[2].samples.?[0].depth_m == null);
    try testing.expect(copies[2].samples.?[0].time_s == null);
}
