const std = @import("std");
const document = @import("../document.zig");
const family_mod = @import("family.zig");
const ldc = @import("bindings.zig").c;

const Allocator = std.mem.Allocator;
const OwnedDocument = document.OwnedDocument;
const Document = document.Document;

pub const ImportOptions = struct {
    family_name: []const u8,
    model: ?u32 = null,
    devtime: u32 = 0,
    systime: ldc.dc_ticks_t = 0,
};

pub fn readDiveComputerDump(allocator: Allocator, bytes: []const u8, options: ImportOptions) !OwnedDocument {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const a = arena.allocator();

    const family = family_mod.familyFromName(options.family_name) orelse return error.UnknownDiveComputerFamily;
    const model = options.model orelse family_mod.defaultModel(family);

    var context: ?*ldc.dc_context_t = null;
    if (ldc.dc_context_new(&context) != ldc.DC_STATUS_SUCCESS) {
        return error.DiveComputerContextFailed;
    }
    defer _ = ldc.dc_context_free(context);
    _ = ldc.dc_context_set_loglevel(context, ldc.DC_LOGLEVEL_NONE);

    const descriptor = try findDescriptor(context, family, model);
    defer ldc.dc_descriptor_free(descriptor);

    var parser: ?*ldc.dc_parser_t = null;
    if (ldc.dc_parser_new2(
        &parser,
        context,
        descriptor,
        bytes.ptr,
        bytes.len,
    ) != ldc.DC_STATUS_SUCCESS) {
        return error.DiveComputerParserFailed;
    }
    defer _ = ldc.dc_parser_destroy(parser);

    const clock_rc = ldc.dc_parser_set_clock(parser, options.devtime, options.systime);
    if (clock_rc != ldc.DC_STATUS_SUCCESS and clock_rc != ldc.DC_STATUS_UNSUPPORTED) {
        return error.DiveComputerParserFailed;
    }

    var dt: ldc.dc_datetime_t = .{};
    const dt_rc = ldc.dc_parser_get_datetime(parser, &dt);
    if (dt_rc != ldc.DC_STATUS_SUCCESS and dt_rc != ldc.DC_STATUS_UNSUPPORTED) {
        return error.DiveComputerParserFailed;
    }

    var divetime_s: u32 = 0;
    const divetime_rc = ldc.dc_parser_get_field(parser, ldc.DC_FIELD_DIVETIME, 0, &divetime_s);
    if (divetime_rc != ldc.DC_STATUS_SUCCESS and divetime_rc != ldc.DC_STATUS_UNSUPPORTED) {
        return error.DiveComputerParserFailed;
    }

    var maxdepth_m: f64 = 0;
    const maxdepth_rc = ldc.dc_parser_get_field(parser, ldc.DC_FIELD_MAXDEPTH, 0, &maxdepth_m);
    if (maxdepth_rc != ldc.DC_STATUS_SUCCESS and maxdepth_rc != ldc.DC_STATUS_UNSUPPORTED) {
        return error.DiveComputerParserFailed;
    }

    var min_temp_c: f64 = 0;
    var has_min_temp = false;
    const temp_rc = ldc.dc_parser_get_field(parser, ldc.DC_FIELD_TEMPERATURE_MINIMUM, 0, &min_temp_c);
    if (temp_rc == ldc.DC_STATUS_SUCCESS) has_min_temp = true;

    var mixes = std.ArrayList(document.Mix).empty;
    errdefer mixes.deinit(a);
    var mix_count: u32 = 0;
    if (ldc.dc_parser_get_field(parser, ldc.DC_FIELD_GASMIX_COUNT, 0, &mix_count) == ldc.DC_STATUS_SUCCESS) {
        var i: u32 = 0;
        while (i < mix_count) : (i += 1) {
            var gas: ldc.dc_gasmix_t = .{};
            if (ldc.dc_parser_get_field(parser, ldc.DC_FIELD_GASMIX, i, &gas) != ldc.DC_STATUS_SUCCESS) continue;
            const id = try std.fmt.allocPrint(a, "mix-{d}", .{i});
            const name = try std.fmt.allocPrint(a, "Gas {d}", .{i});
            try mixes.append(a, .{
                .id = id,
                .name = name,
                .o2 = @floatCast(gas.oxygen),
                .n2 = @floatCast(gas.nitrogen),
                .he = @floatCast(gas.helium),
            });
        }
    }

    var tank_rows = std.ArrayList(document.TankData).empty;
    errdefer tank_rows.deinit(a);
    var tank_count: u32 = 0;
    if (ldc.dc_parser_get_field(parser, ldc.DC_FIELD_TANK_COUNT, 0, &tank_count) == ldc.DC_STATUS_SUCCESS) {
        var i: u32 = 0;
        while (i < tank_count) : (i += 1) {
            var tank: ldc.dc_tank_t = .{};
            if (ldc.dc_parser_get_field(parser, ldc.DC_FIELD_TANK, i, &tank) != ldc.DC_STATUS_SUCCESS) continue;
            var links = std.ArrayList([]const u8).empty;
            errdefer links.deinit(a);
            if (tank.gasmix != ldc.DC_GASMIX_UNKNOWN and tank.gasmix < mix_count) {
                const mix_id = try std.fmt.allocPrint(a, "mix-{d}", .{tank.gasmix});
                try links.append(a, mix_id);
            }
            const begin_pa: f32 = @floatCast(tank.beginpressure * 100_000.0);
            const end_pa: ?f32 = if (tank.endpressure > 0) @floatCast(tank.endpressure * 100_000.0) else null;
            const volume_m3: ?f32 = if (tank.volume > 0) @floatCast(tank.volume / 1000.0) else null;
            try tank_rows.append(a, .{
                .links = try links.toOwnedSlice(a),
                .volume_m3 = volume_m3,
                .pressure_begin_pa = begin_pa,
                .pressure_end_pa = end_pa,
            });
        }
    }

    var sample_ctx = SampleContext.init(a);
    defer sample_ctx.deinit();
    if (ldc.dc_parser_samples_foreach(parser, sampleCallback, &sample_ctx) != ldc.DC_STATUS_SUCCESS) {
        return error.DiveComputerParserFailed;
    }
    try sample_ctx.finishCurrent();

    const datetime = try formatDatetime(a, dt, dt_rc == ldc.DC_STATUS_SUCCESS);
    const dive_id = try a.dupe(u8, "dive-1");
    const group_id = try a.dupe(u8, "import");

    const samples_slice: ?[]const document.Waypoint = if (sample_ctx.waypoints.items.len > 0)
        try sample_ctx.waypoints.toOwnedSlice(a)
    else
        null;

    const duration_s: f32 = if (divetime_s > 0)
        @floatFromInt(divetime_s)
    else if (samples_slice) |s| blk: {
        break :blk s[s.len - 1].time_s orelse 0;
    } else 0;

    const dive = document.Dive{
        .id = dive_id,
        .before = .{
            .datetime = datetime,
            .dive_number = 1,
        },
        .tanks = try tank_rows.toOwnedSlice(a),
        .samples = samples_slice,
        .after = .{
            .greatest_depth_m = @floatCast(maxdepth_m),
            .duration_s = duration_s,
            .lowest_temperature_k = if (has_min_temp) @floatCast(min_temp_c + 273.15) else null,
        },
    };

    const group = document.RepetitionGroup{
        .id = group_id,
        .dives = try a.dupe(document.Dive, &.{dive}),
    };

    const doc = Document{
        .generator = .{
            .name = "openwater",
            .version = "libdivecomputer-import",
        },
        .mixes = if (mixes.items.len > 0) try mixes.toOwnedSlice(a) else null,
        .groups = try a.dupe(document.RepetitionGroup, &.{group}),
    };

    return OwnedDocument.adopt(arena, doc);
}

fn findDescriptor(context: ?*ldc.dc_context_t, family: ldc.dc_family_t, model: u32) !*ldc.dc_descriptor_t {
    var iterator: ?*ldc.dc_iterator_t = null;
    if (ldc.dc_descriptor_iterator_new(&iterator, context) != ldc.DC_STATUS_SUCCESS) {
        return error.DiveComputerDescriptorFailed;
    }
    defer _ = ldc.dc_iterator_free(iterator);

    var fallback: ?*ldc.dc_descriptor_t = null;
    while (true) {
        var descriptor: ?*ldc.dc_descriptor_t = null;
        const rc = ldc.dc_iterator_next(iterator, @ptrCast(&descriptor));
        if (rc == ldc.DC_STATUS_DONE) break;
        if (rc != ldc.DC_STATUS_SUCCESS) return error.DiveComputerDescriptorFailed;

        if (ldc.dc_descriptor_get_type(descriptor) == family) {
            if (ldc.dc_descriptor_get_model(descriptor) == model) {
                if (fallback) |f| ldc.dc_descriptor_free(f);
                return descriptor.?;
            }
            if (fallback == null) {
                fallback = descriptor;
                descriptor = null;
            }
        }
        if (descriptor) |d| ldc.dc_descriptor_free(d);
    }
    if (fallback) |f| return f;
    return error.DiveComputerDescriptorFailed;
}

fn formatDatetime(allocator: Allocator, dt: ldc.dc_datetime_t, has_dt: bool) ![]const u8 {
    if (!has_dt) return allocator.dupe(u8, "1970-01-01T00:00:00Z");
    const year: u32 = @intCast(dt.year);
    const month: u32 = @intCast(dt.month);
    const day: u32 = @intCast(dt.day);
    const hour: u32 = @intCast(dt.hour);
    const minute: u32 = @intCast(dt.minute);
    const second: u32 = @intCast(dt.second);
    if (dt.timezone == ldc.DC_TIMEZONE_NONE) {
        return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
            year, month, day, hour, minute, second,
        });
    }
    const tz_hours: i32 = @divTrunc(dt.timezone, 3600);
    const tz_mins: u32 = @intCast(@abs(@rem(dt.timezone, 3600)) / 60);
    const sign: u8 = if (tz_hours >= 0) '+' else '-';
    const tz_h: u32 = @intCast(@abs(tz_hours));
    return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}{c}{d:0>2}:{d:0>2}", .{
        year, month, day, hour, minute, second, sign, tz_h, tz_mins,
    });
}

const SampleContext = struct {
    allocator: Allocator,
    waypoints: std.ArrayList(document.Waypoint),
    current: document.Waypoint = .{},
    current_pressures: std.ArrayList(document.TankPressure),
    has_current: bool = false,

    fn init(allocator: Allocator) SampleContext {
        return .{
            .allocator = allocator,
            .waypoints = std.ArrayList(document.Waypoint).empty,
            .current_pressures = std.ArrayList(document.TankPressure).empty,
        };
    }

    fn deinit(self: *SampleContext) void {
        self.waypoints.deinit(self.allocator);
        self.current_pressures.deinit(self.allocator);
    }

    fn finishCurrent(self: *SampleContext) !void {
        if (!self.has_current) return;
        self.current.pressures = try self.current_pressures.toOwnedSlice(self.allocator);
        self.current_pressures = std.ArrayList(document.TankPressure).empty;
        try self.waypoints.append(self.allocator, self.current);
        self.current = .{};
        self.has_current = false;
    }
};

fn sampleCallback(
    sample_type: ldc.dc_sample_type_t,
    value: ?*const ldc.dc_sample_value_t,
    userdata: ?*anyopaque,
) callconv(.c) void {
    const ctx: *SampleContext = @ptrCast(@alignCast(userdata.?));
    const v = value orelse return;
    switch (sample_type) {
        ldc.DC_SAMPLE_TIME => {
            ctx.finishCurrent() catch return;
            ctx.has_current = true;
            ctx.current.time_s = @as(f32, @floatFromInt(v.time)) / 1000.0;
        },
        ldc.DC_SAMPLE_DEPTH => {
            if (!ctx.has_current) ctx.has_current = true;
            ctx.current.depth_m = @floatCast(v.depth);
        },
        ldc.DC_SAMPLE_TEMPERATURE => {
            if (!ctx.has_current) ctx.has_current = true;
            ctx.current.temperature_k = @floatCast(v.temperature + 273.15);
        },
        ldc.DC_SAMPLE_PRESSURE => {
            if (!ctx.has_current) ctx.has_current = true;
            const tank_ref = std.fmt.allocPrint(ctx.allocator, "tank-{d}", .{v.pressure.tank + 1}) catch return;
            const pressure_pa: f32 = @floatCast(v.pressure.value * 100_000.0);
            ctx.current_pressures.append(ctx.allocator, .{
                .tank_ref = tank_ref,
                .pressure_pa = pressure_pa,
            }) catch return;
        },
        ldc.DC_SAMPLE_GASMIX => {
            if (!ctx.has_current) ctx.has_current = true;
            const mix_ref = std.fmt.allocPrint(ctx.allocator, "mix-{d}", .{v.gasmix}) catch return;
            ctx.current.switch_mix_ref = mix_ref;
        },
        else => {},
    }
}
