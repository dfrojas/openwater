//! UDDF 3.2.3 logbook subset. See experiments/data_model/DATA_MODEL.md.
const std = @import("std");
const Allocator = std.mem.Allocator;
pub const Generator = struct { name: []const u8, version: ?[]const u8 = null };

pub const Diver = struct { owner: Person, buddies: []const Person = &.{} };

pub const Person = struct {
    id: []const u8,
    first_name: []const u8,
    last_name: []const u8,
    tanks: []const Tank = &.{},
};

pub const Tank = struct {
    id: []const u8,
    name: []const u8,
    volume_m3: ?f32 = null,
};

pub const Geography = struct {
    location: []const u8,
    latitude_deg: ?f32 = null,
    longitude_deg: ?f32 = null,
    altitude_m: ?f32 = null,
};

pub const Site = struct { id: []const u8, name: []const u8, geography: ?Geography = null };

pub const GasLimit = union(enum) { maximum_po2_pa: f32, maximum_depth_m: f32 };

pub const Mix = struct {
    id: []const u8,
    name: []const u8,
    o2: ?f32 = null,
    n2: ?f32 = null,
    he: ?f32 = null,
    ar: ?f32 = null,
    h2: ?f32 = null,
    limit: ?GasLimit = null,
};

pub const SurfaceInterval = union(enum) { infinity, seconds: i64 };

pub const InformationBeforeDive = struct {
    links: []const []const u8 = &.{},
    datetime: []const u8,
    dive_number: ?u32 = null,
    surface_interval: ?SurfaceInterval = null,
    surface_pressure_pa: ?f32 = null,
};

pub const InformationAfterDive = struct {
    greatest_depth_m: f32,
    duration_s: f32,
    lowest_temperature_k: ?f32 = null,
};

pub const TankData = struct {
    links: []const []const u8 = &.{},
    volume_m3: ?f32 = null,
    pressure_begin_pa: f32,
    pressure_end_pa: ?f32 = null,
};

pub const TankPressure = struct { tank_ref: ?[]const u8 = null, pressure_pa: f32 };

pub const Waypoint = struct {
    depth_m: ?f32 = null,
    time_s: ?f32 = null,
    switch_mix_ref: ?[]const u8 = null,
    pressures: []const TankPressure = &.{},
    temperature_k: ?f32 = null,
    heart_rate_per_s: ?f32 = null,
};

pub const Dive = struct {
    id: []const u8,
    before: InformationBeforeDive,
    tanks: []const TankData = &.{},
    samples: ?[]const Waypoint = null,
    after: InformationAfterDive,
};

pub const RepetitionGroup = struct { id: []const u8, dives: []const Dive };

const Kind = enum { owner, buddy, tank, site, mix, group, dive };

const Ids = std.StringHashMap(Kind);

pub const Document = struct {
    generator: Generator,
    diver: ?Diver = null,
    sites: ?[]const Site = null,
    mixes: ?[]const Mix = null,
    groups: ?[]const RepetitionGroup = null,

    pub fn checkReferences(self: Document, allocator: Allocator) !void {
        var ids = Ids.init(allocator);
        defer ids.deinit();
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

    pub fn findMix(self: Document, id: []const u8) ?*const Mix {
        for (self.mixes orelse return null) |*mix| {
            if (std.mem.eql(u8, mix.id, id)) return mix;
        }
        return null;
    }

    pub fn eql(a: Document, b: Document) bool {
        if (!eqlGenerator(a.generator, b.generator)) return false;
        if (!eqlOptionalDiver(a.diver, b.diver)) return false;
        if (!eqlOptionalSites(a.sites, b.sites)) return false;
        if (!eqlOptionalMixes(a.mixes, b.mixes)) return false;
        if (!eqlOptionalGroups(a.groups, b.groups)) return false;
        return true;
    }
};

pub const OwnedDocument = struct {
    arena: std.heap.ArenaAllocator,
    value: Document,

    pub fn init(allocator: Allocator, source: Document) !OwnedDocument {
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
        return .{ .arena = arena, .value = value };
    }

    pub fn adopt(arena: std.heap.ArenaAllocator, value: Document) OwnedDocument {
        return .{ .arena = arena, .value = value };
    }

    pub fn deinit(self: *OwnedDocument) void {
        self.arena.deinit();
        self.* = undefined;
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

fn eqlStr(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn eqlOptionalStr(a: ?[]const u8, b: ?[]const u8) bool {
    if (a) |av| return if (b) |bv| eqlStr(av, bv) else false;
    return b == null;
}

fn eqlOptionalF32(a: ?f32, b: ?f32) bool {
    if (a) |av| return if (b) |bv| av == bv else false;
    return b == null;
}

fn eqlGenerator(a: Generator, b: Generator) bool {
    return eqlStr(a.name, b.name) and eqlOptionalStr(a.version, b.version);
}

fn eqlTank(a: Tank, b: Tank) bool {
    return eqlStr(a.id, b.id) and eqlStr(a.name, b.name) and eqlOptionalF32(a.volume_m3, b.volume_m3);
}

fn eqlPerson(a: Person, b: Person) bool {
    if (!eqlStr(a.id, b.id) or !eqlStr(a.first_name, b.first_name) or !eqlStr(a.last_name, b.last_name))
        return false;
    if (a.tanks.len != b.tanks.len) return false;
    for (a.tanks, b.tanks) |at, bt| if (!eqlTank(at, bt)) return false;
    return true;
}

fn eqlOptionalDiver(a: ?Diver, b: ?Diver) bool {
    if (a) |av| {
        if (b) |bv| return eqlPerson(av.owner, bv.owner) and eqlPersonSlice(av.buddies, bv.buddies);
        return false;
    }
    return b == null;
}

fn eqlPersonSlice(a: []const Person, b: []const Person) bool {
    if (a.len != b.len) return false;
    for (a, b) |ap, bp| if (!eqlPerson(ap, bp)) return false;
    return true;
}

fn eqlGeography(a: Geography, b: Geography) bool {
    return eqlStr(a.location, b.location) and
        eqlOptionalF32(a.latitude_deg, b.latitude_deg) and
        eqlOptionalF32(a.longitude_deg, b.longitude_deg) and
        eqlOptionalF32(a.altitude_m, b.altitude_m);
}

fn eqlSite(a: Site, b: Site) bool {
    if (!eqlStr(a.id, b.id) or !eqlStr(a.name, b.name)) return false;
    if (a.geography) |ag| return if (b.geography) |bg| eqlGeography(ag, bg) else false;
    return b.geography == null;
}

fn eqlOptionalSites(a: ?[]const Site, b: ?[]const Site) bool {
    if (a) |as| {
        if (b) |bs| {
            if (as.len != bs.len) return false;
            for (as, bs) |site_a, site_b| if (!eqlSite(site_a, site_b)) return false;
            return true;
        }
        return false;
    }
    return b == null;
}

fn eqlMix(a: Mix, b: Mix) bool {
    if (!eqlStr(a.id, b.id) or !eqlStr(a.name, b.name)) return false;
    if (!eqlOptionalF32(a.o2, b.o2) or !eqlOptionalF32(a.n2, b.n2)) return false;
    if (!eqlOptionalF32(a.he, b.he) or !eqlOptionalF32(a.ar, b.ar)) return false;
    if (!eqlOptionalF32(a.h2, b.h2)) return false;
    if (a.limit) |al| {
        if (b.limit) |bl| return std.meta.eql(al, bl);
        return false;
    }
    return b.limit == null;
}

fn eqlOptionalMixes(a: ?[]const Mix, b: ?[]const Mix) bool {
    if (a) |as| {
        if (b) |bs| {
            if (as.len != bs.len) return false;
            for (as, bs) |mix_a, mix_b| if (!eqlMix(mix_a, mix_b)) return false;
            return true;
        }
        return false;
    }
    return b == null;
}

fn eqlSurfaceInterval(a: SurfaceInterval, b: SurfaceInterval) bool {
    return std.meta.eql(a, b);
}

fn eqlBefore(a: InformationBeforeDive, b: InformationBeforeDive) bool {
    if (!eqlStr(a.datetime, b.datetime)) return false;
    if (!eqlOptionalF32(a.surface_pressure_pa, b.surface_pressure_pa)) return false;
    if (a.dive_number != b.dive_number) return false;
    if (a.surface_interval) |si| {
        if (b.surface_interval) |sb| {
            if (!eqlSurfaceInterval(si, sb)) return false;
        } else return false;
    } else if (b.surface_interval != null) return false;
    if (a.links.len != b.links.len) return false;
    for (a.links, b.links) |la, lb| if (!eqlStr(la, lb)) return false;
    return true;
}

fn eqlAfter(a: InformationAfterDive, b: InformationAfterDive) bool {
    return a.greatest_depth_m == b.greatest_depth_m and
        a.duration_s == b.duration_s and
        eqlOptionalF32(a.lowest_temperature_k, b.lowest_temperature_k);
}

fn eqlTankData(a: TankData, b: TankData) bool {
    if (a.pressure_begin_pa != b.pressure_begin_pa) return false;
    if (!eqlOptionalF32(a.volume_m3, b.volume_m3)) return false;
    if (!eqlOptionalF32(a.pressure_end_pa, b.pressure_end_pa)) return false;
    if (a.links.len != b.links.len) return false;
    for (a.links, b.links) |la, lb| if (!eqlStr(la, lb)) return false;
    return true;
}

fn eqlTankPressure(a: TankPressure, b: TankPressure) bool {
    return a.pressure_pa == b.pressure_pa and eqlOptionalStr(a.tank_ref, b.tank_ref);
}

fn eqlWaypoint(a: Waypoint, b: Waypoint) bool {
    if (!eqlOptionalF32(a.depth_m, b.depth_m) or !eqlOptionalF32(a.time_s, b.time_s)) return false;
    if (!eqlOptionalStr(a.switch_mix_ref, b.switch_mix_ref)) return false;
    if (!eqlOptionalF32(a.temperature_k, b.temperature_k)) return false;
    if (!eqlOptionalF32(a.heart_rate_per_s, b.heart_rate_per_s)) return false;
    if (a.pressures.len != b.pressures.len) return false;
    for (a.pressures, b.pressures) |pa, pb| if (!eqlTankPressure(pa, pb)) return false;
    return true;
}

fn eqlDive(a: Dive, b: Dive) bool {
    if (!eqlStr(a.id, b.id) or !eqlBefore(a.before, b.before) or !eqlAfter(a.after, b.after)) return false;
    if (a.tanks.len != b.tanks.len) return false;
    for (a.tanks, b.tanks) |ta, tb| if (!eqlTankData(ta, tb)) return false;
    if (a.samples) |as| {
        if (b.samples) |bs| {
            if (as.len != bs.len) return false;
            for (as, bs) |wa, wb| if (!eqlWaypoint(wa, wb)) return false;
            return true;
        }
        return false;
    }
    return b.samples == null;
}

fn eqlOptionalGroups(a: ?[]const RepetitionGroup, b: ?[]const RepetitionGroup) bool {
    if (a) |as| {
        if (b) |bs| {
            if (as.len != bs.len) return false;
            for (as, bs) |ga, gb| {
                if (!eqlStr(ga.id, gb.id) or ga.dives.len != gb.dives.len) return false;
                for (ga.dives, gb.dives) |da, db| if (!eqlDive(da, db)) return false;
            }
            return true;
        }
        return false;
    }
    return b == null;
}
