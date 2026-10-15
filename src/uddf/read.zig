const std = @import("std");
const document = @import("../document.zig");
const xml = @import("../xml/mod.zig");

const Allocator = std.mem.Allocator;
const OwnedDocument = document.OwnedDocument;

pub fn readUddf(allocator: Allocator, bytes: []const u8) !OwnedDocument {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const a = arena.allocator();
    const stored = try a.dupe(u8, bytes);

    var builder = try Builder.init(a);
    defer builder.deinit();

    var reader = xml.Reader.init(a, stored);
    defer reader.deinit();
    reader.start();
    while (true) {
        const event = try reader.next();
        switch (event) {
            .eof => break,
            else => try builder.handle(event),
        }
    }

    const doc = try builder.finish();
    return OwnedDocument.adopt(arena, doc);
}

const Builder = struct {
    allocator: Allocator,
    generator: document.Generator = .{ .name = "" },
    diver: ?document.Diver = null,
    sites: std.ArrayList(document.Site),
    mixes: std.ArrayList(document.Mix),
    groups: std.ArrayList(document.RepetitionGroup),
    skip_depth: usize = 0,
    text_leaf: ?TextLeaf = null,

    owner: PersonBuilder,
    buddies: std.ArrayList(PersonBuilder),
    active_person: enum { owner, buddy } = .owner,

    current_site: SiteBuilder,
    current_mix: MixBuilder,
    current_group: GroupBuilder,
    current_dive: DiveBuilder,
    in_generator: bool = false,
    in_site_section: bool = false,
    in_mix_section: bool = false,
    in_equipment: bool = false,
    diver_owner: ?document.Person = null,

    fn init(allocator: Allocator) !Builder {
        const owner = PersonBuilder.init(allocator);
        return .{
            .allocator = allocator,
            .sites = std.ArrayList(document.Site).empty,
            .mixes = std.ArrayList(document.Mix).empty,
            .groups = std.ArrayList(document.RepetitionGroup).empty,
            .buddies = std.ArrayList(PersonBuilder).empty,
            .owner = owner,
            .current_site = .{},
            .current_mix = .{},
            .current_group = .{},
            .current_dive = try DiveBuilder.init(allocator),
        };
    }

    fn deinit(self: *Builder) void {
        self.sites.deinit(self.allocator);
        self.mixes.deinit(self.allocator);
        self.groups.deinit(self.allocator);
        self.buddies.deinit(self.allocator);
        self.current_dive.deinit(self.allocator);
    }

    fn handle(self: *Builder, event: xml.Event) !void {
        switch (event) {
            .start_element => |el| {
                if (self.skip_depth > 0) {
                    self.skip_depth += 1;
                    return;
                }
                self.text_leaf = null;
                if (try self.onStart(el.name, el.attrs)) return;
                self.skip_depth = 1;
            },
            .end_element => |name| {
                if (self.skip_depth > 0) {
                    self.skip_depth -= 1;
                    return;
                }
                self.text_leaf = null;
                try self.onEnd(name);
            },
            .text => |text| try self.onText(text),
            .eof => {},
        }
    }

    fn onStart(self: *Builder, name: []const u8, attrs: []const xml.Attr) !bool {
        const n = localName(name);
        if (eql(n, "uddf") or eql(n, "diver") or eql(n, "divesite") or eql(n, "gasdefinitions") or
            eql(n, "profiledata") or eql(n, "personal") or eql(n, "geography") or
            eql(n, "surfaceintervalbeforedive") or eql(n, "samples"))
            return true;
        if (eql(n, "generator")) {
            self.in_generator = true;
            return true;
        }
        if (eql(n, "equipment")) {
            self.in_equipment = true;
            return true;
        }
        if (eql(n, "informationbeforedive")) {
            self.current_dive.in_before = true;
            return true;
        }
        if (eql(n, "informationafterdive")) {
            self.current_dive.in_after = true;
            return true;
        }

        if (eql(n, "owner")) {
            self.active_person = .owner;
            self.owner.id = attr(attrs, "id") orelse return error.MissingId;
            return true;
        }
        if (eql(n, "buddy")) {
            self.active_person = .buddy;
            var buddy = PersonBuilder.init(self.allocator);
            buddy.id = attr(attrs, "id") orelse return error.MissingId;
            try self.buddies.append(self.allocator, buddy);
            return true;
        }
        if (eql(n, "tank") and self.in_equipment) {
            const id = attr(attrs, "id") orelse return error.MissingId;
            try self.activePerson().tanks.append(self.allocator, .{ .id = id });
            return true;
        }
        if (eql(n, "site")) {
            self.in_site_section = true;
            self.current_site.id = attr(attrs, "id") orelse return error.MissingId;
            return true;
        }
        if (eql(n, "mix")) {
            self.in_mix_section = true;
            self.current_mix.id = attr(attrs, "id") orelse return error.MissingId;
            return true;
        }
        if (eql(n, "repetitiongroup")) {
            self.current_group = .{ .id = attr(attrs, "id") orelse return error.MissingId };
            self.current_group.dives = std.ArrayList(document.Dive).empty;
            return true;
        }
        if (eql(n, "dive")) {
            self.current_dive.reset(attr(attrs, "id") orelse return error.MissingId);
            return true;
        }
        if (eql(n, "infinity")) {
            self.current_dive.before.surface_interval = .infinity;
            return true;
        }
        if (eql(n, "link")) {
            const ref = attr(attrs, "ref") orelse return true;
            const duped = try self.allocator.dupe(u8, ref);
            if (self.current_dive.in_before) {
                try self.current_dive.before.links.append(self.allocator, duped);
            } else if (self.current_dive.in_tankdata) {
                try self.current_dive.tank.links.append(self.allocator, duped);
            }
            return true;
        }
        if (eql(n, "tankdata")) {
            self.current_dive.in_tankdata = true;
            self.current_dive.tank = TankDataBuilder.init();
            return true;
        }
        if (eql(n, "waypoint")) {
            try self.current_dive.waypoints.append(self.allocator, WaypointBuilder.init());
            return true;
        }
        if (eql(n, "switchmix")) {
            if (attr(attrs, "ref")) |ref| {
                const wp = self.currentWaypoint();
                wp.switch_mix_ref = try self.allocator.dupe(u8, ref);
            }
            return true;
        }
        if (eql(n, "tankpressure")) {
            try self.currentWaypoint().pressures.append(self.allocator, .{
                .tank_ref = if (attr(attrs, "tankref")) |r| try self.allocator.dupe(u8, r) else null,
                .pressure_pa = 0,
            });
            self.text_leaf = .tankpressure_value;
            return true;
        }

        if (eql(n, "name")) {
            self.text_leaf = if (self.in_equipment) .tank_name else if (self.in_mix_section) .mix_name else if (self.in_site_section) .site_name else if (self.in_generator) .generator_name else null;
            return true;
        }
        if (eql(n, "version")) {
            self.text_leaf = .generator_version;
            return true;
        }
        if (eql(n, "firstname")) {
            self.text_leaf = .person_first;
            return true;
        }
        if (eql(n, "lastname")) {
            self.text_leaf = .person_last;
            return true;
        }
        if (eql(n, "location")) {
            self.text_leaf = .site_location;
            return true;
        }
        if (eql(n, "latitude")) {
            self.text_leaf = .site_latitude;
            return true;
        }
        if (eql(n, "longitude")) {
            self.text_leaf = .site_longitude;
            return true;
        }
        if (eql(n, "altitude")) {
            self.text_leaf = .site_altitude;
            return true;
        }
        if (eql(n, "o2")) {
            self.text_leaf = .mix_o2;
            return true;
        }
        if (eql(n, "n2")) {
            self.text_leaf = .mix_n2;
            return true;
        }
        if (eql(n, "he")) {
            self.text_leaf = .mix_he;
            return true;
        }
        if (eql(n, "ar")) {
            self.text_leaf = .mix_ar;
            return true;
        }
        if (eql(n, "h2")) {
            self.text_leaf = .mix_h2;
            return true;
        }
        if (eql(n, "maximumpo2")) {
            self.text_leaf = .mix_max_po2;
            return true;
        }
        if (eql(n, "maximumoperationdepth")) {
            self.text_leaf = .mix_max_depth;
            return true;
        }
        if (eql(n, "datetime")) {
            self.text_leaf = .before_datetime;
            return true;
        }
        if (eql(n, "divenumber")) {
            self.text_leaf = .before_dive_number;
            return true;
        }
        if (eql(n, "surfacepressure")) {
            self.text_leaf = .before_surface_pressure;
            return true;
        }
        if (eql(n, "passedtime")) {
            self.text_leaf = .before_passedtime;
            return true;
        }
        if (eql(n, "tankvolume")) {
            self.text_leaf = if (self.current_dive.in_tankdata) .tankdata_volume else .equip_tank_volume;
            return true;
        }
        if (eql(n, "tankpressurebegin")) {
            self.text_leaf = .tankdata_begin;
            return true;
        }
        if (eql(n, "tankpressureend")) {
            self.text_leaf = .tankdata_end;
            return true;
        }
        if (eql(n, "depth")) {
            self.text_leaf = .wp_depth;
            return true;
        }
        if (eql(n, "divetime")) {
            self.text_leaf = .wp_time;
            return true;
        }
        if (eql(n, "temperature")) {
            self.text_leaf = .wp_temperature;
            return true;
        }
        if (eql(n, "heartrate")) {
            self.text_leaf = .wp_heartrate;
            return true;
        }
        if (eql(n, "greatestdepth")) {
            self.text_leaf = .after_greatest_depth;
            return true;
        }
        if (eql(n, "diveduration")) {
            self.text_leaf = .after_duration;
            return true;
        }
        if (eql(n, "lowesttemperature")) {
            self.text_leaf = .after_lowest_temp;
            return true;
        }
        return false;
    }

    fn onEnd(self: *Builder, name: []const u8) !void {
        const n = localName(name);
        if (eql(n, "generator")) self.in_generator = false;
        if (eql(n, "equipment")) self.in_equipment = false;
        if (eql(n, "owner")) {
            self.diver_owner = try self.owner.finish(self.allocator);
            self.owner = PersonBuilder.init(self.allocator);
            return;
        }
        if (eql(n, "diver")) {
            const buddies = try self.finishBuddies();
            self.diver = .{ .owner = self.diver_owner orelse return error.MissingOwner, .buddies = buddies };
            self.diver_owner = null;
            return;
        }
        if (eql(n, "site")) {
            try self.sites.append(self.allocator, try self.current_site.finish(self.allocator));
            self.current_site = .{};
            self.in_site_section = false;
            return;
        }
        if (eql(n, "mix")) {
            try self.mixes.append(self.allocator, try self.current_mix.finish(self.allocator));
            self.current_mix = .{};
            self.in_mix_section = false;
            return;
        }
        if (eql(n, "repetitiongroup")) {
            try self.groups.append(self.allocator, .{
                .id = try self.allocator.dupe(u8, self.current_group.id),
                .dives = try self.current_group.dives.toOwnedSlice(self.allocator),
            });
            self.current_group = .{};
            return;
        }
        if (eql(n, "dive")) {
            try self.current_group.dives.append(self.allocator, try self.current_dive.finish());
            return;
        }
        if (eql(n, "informationbeforedive")) self.current_dive.in_before = false;
        if (eql(n, "informationafterdive")) self.current_dive.in_after = false;
        if (eql(n, "tankdata")) {
            try self.current_dive.tanks.append(self.allocator, try self.current_dive.tank.finish(self.allocator));
            self.current_dive.in_tankdata = false;
        }
    }

    fn onText(self: *Builder, text: []const u8) !void {
        if (self.skip_depth > 0 or text.len == 0) return;
        const leaf = self.text_leaf orelse return;
        switch (leaf) {
            .generator_name => self.generator.name = try self.allocator.dupe(u8, text),
            .generator_version => self.generator.version = try self.allocator.dupe(u8, text),
            .person_first => try self.activePerson().setFirst(self.allocator, text),
            .person_last => try self.activePerson().setLast(self.allocator, text),
            .tank_name => try self.activePerson().setTankName(self.allocator, text),
            .equip_tank_volume => try self.activePerson().setTankVolume(parseF32(text)),
            .site_name => self.current_site.name = try self.allocator.dupe(u8, text),
            .site_location => self.current_site.location = try self.allocator.dupe(u8, text),
            .site_latitude => self.current_site.latitude = parseF32(text),
            .site_longitude => self.current_site.longitude = parseF32(text),
            .site_altitude => self.current_site.altitude = parseF32(text),
            .mix_name => self.current_mix.name = try self.allocator.dupe(u8, text),
            .mix_o2 => self.current_mix.o2 = parseF32(text),
            .mix_n2 => self.current_mix.n2 = parseF32(text),
            .mix_he => self.current_mix.he = parseF32(text),
            .mix_ar => self.current_mix.ar = parseF32(text),
            .mix_h2 => self.current_mix.h2 = parseF32(text),
            .mix_max_po2 => self.current_mix.limit = .{ .maximum_po2_pa = parseF32(text) },
            .mix_max_depth => self.current_mix.limit = .{ .maximum_depth_m = parseF32(text) },
            .before_datetime => self.current_dive.before.datetime = try self.allocator.dupe(u8, text),
            .before_dive_number => self.current_dive.before.dive_number = @intFromFloat(parseF32(text)),
            .before_surface_pressure => self.current_dive.before.surface_pressure_pa = parseF32(text),
            .before_passedtime => self.current_dive.before.surface_interval = .{ .seconds = @intFromFloat(parseF32(text)) },
            .tankdata_volume => self.current_dive.tank.volume_m3 = parseF32(text),
            .tankdata_begin => self.current_dive.tank.pressure_begin_pa = parseF32(text),
            .tankdata_end => self.current_dive.tank.pressure_end_pa = parseF32(text),
            .wp_depth => self.currentWaypoint().depth_m = parseF32(text),
            .wp_time => self.currentWaypoint().time_s = parseF32(text),
            .wp_temperature => self.currentWaypoint().temperature_k = parseF32(text),
            .wp_heartrate => self.currentWaypoint().heart_rate_per_s = parseF32(text),
            .after_greatest_depth => self.current_dive.after.greatest_depth_m = parseF32(text),
            .after_duration => self.current_dive.after.duration_s = parseF32(text),
            .after_lowest_temp => self.current_dive.after.lowest_temperature_k = parseF32(text),
            .tankpressure_value => {
                const wp = self.currentWaypoint();
                if (wp.pressures.items.len > 0) {
                    wp.pressures.items[wp.pressures.items.len - 1].pressure_pa = parseF32(text);
                }
            },
        }
    }

    fn activePerson(self: *Builder) *PersonBuilder {
        if (self.active_person == .buddy and self.buddies.items.len > 0) {
            return &self.buddies.items[self.buddies.items.len - 1];
        }
        return &self.owner;
    }

    fn currentWaypoint(self: *Builder) *WaypointBuilder {
        return &self.current_dive.waypoints.items[self.current_dive.waypoints.items.len - 1];
    }

    fn finishBuddies(self: *Builder) ![]document.Person {
        const out = try self.allocator.alloc(document.Person, self.buddies.items.len);
        for (self.buddies.items, 0..) |buddy, i| out[i] = try buddy.finish(self.allocator);
        self.buddies.clearRetainingCapacity();
        return out;
    }

    fn finish(self: *Builder) !document.Document {
        if (self.generator.name.len == 0) return error.MissingGenerator;
        return .{
            .generator = self.generator,
            .diver = self.diver,
            .sites = if (self.sites.items.len > 0) try self.sites.toOwnedSlice(self.allocator) else null,
            .mixes = if (self.mixes.items.len > 0) try self.mixes.toOwnedSlice(self.allocator) else null,
            .groups = if (self.groups.items.len > 0) try self.groups.toOwnedSlice(self.allocator) else null,
        };
    }
};

const TextLeaf = enum {
    generator_name,
    generator_version,
    person_first,
    person_last,
    tank_name,
    equip_tank_volume,
    site_name,
    site_location,
    site_latitude,
    site_longitude,
    site_altitude,
    mix_name,
    mix_o2,
    mix_n2,
    mix_he,
    mix_ar,
    mix_h2,
    mix_max_po2,
    mix_max_depth,
    before_datetime,
    before_dive_number,
    before_surface_pressure,
    before_passedtime,
    tankdata_volume,
    tankdata_begin,
    tankdata_end,
    wp_depth,
    wp_time,
    wp_temperature,
    wp_heartrate,
    tankpressure_value,
    after_greatest_depth,
    after_duration,
    after_lowest_temp,
};

const PersonBuilder = struct {
    id: []const u8 = "",
    first_name: []const u8 = "",
    last_name: []const u8 = "",
    tanks: std.ArrayList(TankScratch),

    fn init(_: Allocator) PersonBuilder {
        return .{ .tanks = std.ArrayList(TankScratch).empty };
    }

    fn setFirst(self: *PersonBuilder, a: Allocator, text: []const u8) !void {
        self.first_name = try a.dupe(u8, text);
    }
    fn setLast(self: *PersonBuilder, a: Allocator, text: []const u8) !void {
        self.last_name = try a.dupe(u8, text);
    }
    fn setTankName(self: *PersonBuilder, a: Allocator, text: []const u8) !void {
        if (self.tanks.items.len == 0) return;
        self.tanks.items[self.tanks.items.len - 1].name = try a.dupe(u8, text);
    }
    fn setTankVolume(self: *PersonBuilder, value: f32) !void {
        if (self.tanks.items.len == 0) return;
        self.tanks.items[self.tanks.items.len - 1].volume_m3 = value;
    }
    fn finish(self: PersonBuilder, a: Allocator) !document.Person {
        var tanks = std.ArrayList(document.Tank).empty;
        defer tanks.deinit(a);
        for (self.tanks.items) |t| {
            try tanks.append(a, .{
                .id = try a.dupe(u8, t.id),
                .name = try a.dupe(u8, t.name),
                .volume_m3 = t.volume_m3,
            });
        }
        return .{
            .id = try a.dupe(u8, self.id),
            .first_name = try a.dupe(u8, self.first_name),
            .last_name = try a.dupe(u8, self.last_name),
            .tanks = try tanks.toOwnedSlice(a),
        };
    }
};

const TankScratch = struct { id: []const u8, name: []const u8 = "", volume_m3: ?f32 = null };

const SiteBuilder = struct {
    id: []const u8 = "",
    name: []const u8 = "",
    location: ?[]const u8 = null,
    latitude: ?f32 = null,
    longitude: ?f32 = null,
    altitude: ?f32 = null,

    fn finish(self: SiteBuilder, a: Allocator) !document.Site {
        const geography: ?document.Geography = if (self.location != null or self.latitude != null or self.longitude != null or self.altitude != null)
            .{
                .location = try a.dupe(u8, self.location orelse ""),
                .latitude_deg = self.latitude,
                .longitude_deg = self.longitude,
                .altitude_m = self.altitude,
            }
        else
            null;
        return .{
            .id = try a.dupe(u8, self.id),
            .name = try a.dupe(u8, self.name),
            .geography = geography,
        };
    }
};

const MixBuilder = struct {
    id: []const u8 = "",
    name: []const u8 = "",
    o2: ?f32 = null,
    n2: ?f32 = null,
    he: ?f32 = null,
    ar: ?f32 = null,
    h2: ?f32 = null,
    limit: ?document.GasLimit = null,

    fn finish(self: MixBuilder, a: Allocator) !document.Mix {
        return .{
            .id = try a.dupe(u8, self.id),
            .name = try a.dupe(u8, self.name),
            .o2 = self.o2,
            .n2 = self.n2,
            .he = self.he,
            .ar = self.ar,
            .h2 = self.h2,
            .limit = self.limit,
        };
    }
};

const GroupBuilder = struct {
    id: []const u8 = "",
    dives: std.ArrayList(document.Dive) = std.ArrayList(document.Dive).empty,
};

const TankDataBuilder = struct {
    links: std.ArrayList([]const u8),
    volume_m3: ?f32 = null,
    pressure_begin_pa: f32 = 0,
    pressure_end_pa: ?f32 = null,

    fn init() TankDataBuilder {
        return .{ .links = std.ArrayList([]const u8).empty };
    }
    fn finish(self: *TankDataBuilder, a: Allocator) !document.TankData {
        return .{
            .links = try self.links.toOwnedSlice(a),
            .volume_m3 = self.volume_m3,
            .pressure_begin_pa = self.pressure_begin_pa,
            .pressure_end_pa = self.pressure_end_pa,
        };
    }
};

const WaypointBuilder = struct {
    depth_m: ?f32 = null,
    time_s: ?f32 = null,
    switch_mix_ref: ?[]const u8 = null,
    pressures: std.ArrayList(document.TankPressure),
    temperature_k: ?f32 = null,
    heart_rate_per_s: ?f32 = null,

    fn init() WaypointBuilder {
        return .{ .pressures = std.ArrayList(document.TankPressure).empty };
    }
    fn finish(self: *WaypointBuilder, a: Allocator) !document.Waypoint {
        return .{
            .depth_m = self.depth_m,
            .time_s = self.time_s,
            .switch_mix_ref = self.switch_mix_ref,
            .pressures = try self.pressures.toOwnedSlice(a),
            .temperature_k = self.temperature_k,
            .heart_rate_per_s = self.heart_rate_per_s,
        };
    }
};

const DiveBuilder = struct {
    allocator: Allocator,
    id: []const u8 = "",
    before: BeforeBuilder,
    after: document.InformationAfterDive = .{ .greatest_depth_m = 0, .duration_s = 0 },
    tanks: std.ArrayList(document.TankData),
    waypoints: std.ArrayList(WaypointBuilder),
    tank: TankDataBuilder,
    in_before: bool = false,
    in_after: bool = false,
    in_tankdata: bool = false,

    fn init(a: Allocator) !DiveBuilder {
        return .{
            .allocator = a,
            .before = BeforeBuilder.init(),
            .tanks = std.ArrayList(document.TankData).empty,
            .waypoints = std.ArrayList(WaypointBuilder).empty,
            .tank = TankDataBuilder.init(),
        };
    }

    fn deinit(self: *DiveBuilder, a: Allocator) void {
        self.before.links.deinit(a);
        self.tanks.deinit(a);
        self.waypoints.deinit(a);
        self.tank.links.deinit(a);
    }

    fn reset(self: *DiveBuilder, id: []const u8) void {
        self.id = id;
        self.before = BeforeBuilder.init();
        self.after = .{ .greatest_depth_m = 0, .duration_s = 0 };
        self.tanks.clearRetainingCapacity();
        self.waypoints.clearRetainingCapacity();
        self.tank = TankDataBuilder.init();
        self.in_before = true;
        self.in_after = false;
        self.in_tankdata = false;
    }

    fn finish(self: *DiveBuilder) !document.Dive {
        const samples: ?[]document.Waypoint = if (self.waypoints.items.len > 0) blk: {
            const out = try self.allocator.alloc(document.Waypoint, self.waypoints.items.len);
            for (self.waypoints.items, 0..) |*wp, i| out[i] = try wp.finish(self.allocator);
            break :blk out;
        } else null;
        return .{
            .id = try self.allocator.dupe(u8, self.id),
            .before = try self.before.finish(self.allocator),
            .tanks = try self.tanks.toOwnedSlice(self.allocator),
            .samples = samples,
            .after = self.after,
        };
    }
};

const BeforeBuilder = struct {
    links: std.ArrayList([]const u8),
    datetime: []const u8 = "",
    dive_number: ?u32 = null,
    surface_interval: ?document.SurfaceInterval = null,
    surface_pressure_pa: ?f32 = null,

    fn init() BeforeBuilder {
        return .{ .links = std.ArrayList([]const u8).empty };
    }
    fn finish(self: *BeforeBuilder, a: Allocator) !document.InformationBeforeDive {
        if (self.datetime.len == 0) return error.MissingDatetime;
        return .{
            .links = try self.links.toOwnedSlice(a),
            .datetime = self.datetime,
            .dive_number = self.dive_number,
            .surface_interval = self.surface_interval,
            .surface_pressure_pa = self.surface_pressure_pa,
        };
    }
};

fn parseF32(text: []const u8) f32 {
    return std.fmt.parseFloat(f32, text) catch 0;
}

fn attr(attrs: []const xml.Attr, name: []const u8) ?[]const u8 {
    for (attrs) |a| if (eql(a.name, name)) return a.value;
    return null;
}

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn localName(name: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, name, ':')) |idx| return name[idx + 1 ..];
    return name;
}
