const std = @import("std");
const ldc = @import("bindings.zig").c;

pub const Backend = struct {
    name: []const u8,
    family: ldc.dc_family_t,
    model: u32,
};

/// Mirrors dctool `g_backends` (libdivecomputer 0.9.0).
pub const backends = [_]Backend{
    .{ .name = "solution", .family = ldc.DC_FAMILY_SUUNTO_SOLUTION, .model = 0 },
    .{ .name = "eon", .family = ldc.DC_FAMILY_SUUNTO_EON, .model = 0 },
    .{ .name = "vyper", .family = ldc.DC_FAMILY_SUUNTO_VYPER, .model = 0x0A },
    .{ .name = "vyper2", .family = ldc.DC_FAMILY_SUUNTO_VYPER2, .model = 0x10 },
    .{ .name = "d9", .family = ldc.DC_FAMILY_SUUNTO_D9, .model = 0x0E },
    .{ .name = "eonsteel", .family = ldc.DC_FAMILY_SUUNTO_EONSTEEL, .model = 0 },
    .{ .name = "aladin", .family = ldc.DC_FAMILY_UWATEC_ALADIN, .model = 0x3F },
    .{ .name = "memomouse", .family = ldc.DC_FAMILY_UWATEC_MEMOMOUSE, .model = 0 },
    .{ .name = "smart", .family = ldc.DC_FAMILY_UWATEC_SMART, .model = 0x10 },
    .{ .name = "sensus", .family = ldc.DC_FAMILY_REEFNET_SENSUS, .model = 1 },
    .{ .name = "sensuspro", .family = ldc.DC_FAMILY_REEFNET_SENSUSPRO, .model = 2 },
    .{ .name = "sensusultra", .family = ldc.DC_FAMILY_REEFNET_SENSUSULTRA, .model = 3 },
    .{ .name = "vtpro", .family = ldc.DC_FAMILY_OCEANIC_VTPRO, .model = 0x4245 },
    .{ .name = "veo250", .family = ldc.DC_FAMILY_OCEANIC_VEO250, .model = 0x424C },
    .{ .name = "atom2", .family = ldc.DC_FAMILY_OCEANIC_ATOM2, .model = 0x4342 },
    .{ .name = "i330r", .family = ldc.DC_FAMILY_PELAGIC_I330R, .model = 0x4744 },
    .{ .name = "nemo", .family = ldc.DC_FAMILY_MARES_NEMO, .model = 0 },
    .{ .name = "puck", .family = ldc.DC_FAMILY_MARES_PUCK, .model = 7 },
    .{ .name = "darwin", .family = ldc.DC_FAMILY_MARES_DARWIN, .model = 0 },
    .{ .name = "iconhd", .family = ldc.DC_FAMILY_MARES_ICONHD, .model = 0x14 },
    .{ .name = "ostc", .family = ldc.DC_FAMILY_HW_OSTC, .model = 0 },
    .{ .name = "frog", .family = ldc.DC_FAMILY_HW_FROG, .model = 0 },
    .{ .name = "ostc3", .family = ldc.DC_FAMILY_HW_OSTC3, .model = 0 },
    .{ .name = "edy", .family = ldc.DC_FAMILY_CRESSI_EDY, .model = 0x08 },
    .{ .name = "leonardo", .family = ldc.DC_FAMILY_CRESSI_LEONARDO, .model = 1 },
    .{ .name = "goa", .family = ldc.DC_FAMILY_CRESSI_GOA, .model = 2 },
    .{ .name = "n2ition3", .family = ldc.DC_FAMILY_ZEAGLE_N2ITION3, .model = 0 },
    .{ .name = "cobalt", .family = ldc.DC_FAMILY_ATOMICS_COBALT, .model = 0 },
    .{ .name = "predator", .family = ldc.DC_FAMILY_SHEARWATER_PREDATOR, .model = 2 },
    .{ .name = "petrel", .family = ldc.DC_FAMILY_SHEARWATER_PETREL, .model = 3 },
    .{ .name = "nitekq", .family = ldc.DC_FAMILY_DIVERITE_NITEKQ, .model = 0 },
    .{ .name = "aqualand", .family = ldc.DC_FAMILY_CITIZEN_AQUALAND, .model = 0 },
    .{ .name = "idive", .family = ldc.DC_FAMILY_DIVESYSTEM_IDIVE, .model = 0x03 },
    .{ .name = "cochran", .family = ldc.DC_FAMILY_COCHRAN_COMMANDER, .model = 0 },
    .{ .name = "divecomputereu", .family = ldc.DC_FAMILY_TECDIVING_DIVECOMPUTEREU, .model = 0 },
    .{ .name = "extreme", .family = ldc.DC_FAMILY_MCLEAN_EXTREME, .model = 0 },
    .{ .name = "lynx", .family = ldc.DC_FAMILY_LIQUIVISION_LYNX, .model = 0 },
    .{ .name = "sp2", .family = ldc.DC_FAMILY_SPORASUB_SP2, .model = 0 },
    .{ .name = "excursion", .family = ldc.DC_FAMILY_DEEPSIX_EXCURSION, .model = 0 },
    .{ .name = "screen", .family = ldc.DC_FAMILY_SEAC_SCREEN, .model = 0 },
    .{ .name = "cosmiq", .family = ldc.DC_FAMILY_DEEPBLU_COSMIQ, .model = 0 },
    .{ .name = "s1", .family = ldc.DC_FAMILY_OCEANS_S1, .model = 0 },
    .{ .name = "freedom", .family = ldc.DC_FAMILY_DIVESOFT_FREEDOM, .model = 19 },
    .{ .name = "symbios", .family = ldc.DC_FAMILY_HALCYON_SYMBIOS, .model = 1 },
};

pub fn familyFromName(name: []const u8) ?ldc.dc_family_t {
    for (backends) |entry| {
        if (std.mem.eql(u8, name, entry.name)) return entry.family;
    }
    return null;
}

pub fn defaultModel(family: ldc.dc_family_t) u32 {
    for (backends) |entry| {
        if (entry.family == family) return entry.model;
    }
    return 0;
}
