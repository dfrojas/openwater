# UDDF data-model experiment

Status: **experimental; production design requires approval**. Target: UDDF 3.2.3.
Implementation: [`sandbox/data_model.zig`](sandbox/data_model.zig), tested directly
with Zig 0.17.0. No production exports, parser, or serializer.

## Evidence and scope

Primary sources:

- [UDDF 3.2.3 manual](https://www.streit.cc/resources/UDDF/v3.2.3/en/),
  [actual 3.2.3 XSD](https://www.streit.cc/resources/UDDF/v3.2.3/schema/uddf_3.2.3.xsd),
  [cross-references](https://www.streit.cc/resources/UDDF/v3.2.3/en/cross-referencing.html),
  and [units](https://www.streit.cc/resources/UDDF/v3.2.3/en/units.html).
- Official [profile example](https://www.streit.cc/resources/UDDF/v3.2.3/en/examples_dive-profiles.html)
  and [gas/equipment example](https://www.streit.cc/resources/UDDF/v3.2.3/en/examples_breathing-gases-used.html).
  These illustrate relationships, but contain older, non-XSD-conforming forms.
- Repository: `src/root.zig` has no public model; `src/main.zig` only inspects files.
  `sandbox/min.uddf` illustrates one gas and one recorded dive, labelled 3.2.1.
- [libflightplan build](https://github.com/mitchellh/libflightplan/blob/main/build.zig)
  was inspected as the project reference. Its library/CLI separation and native
  Zig tests are relevant; its older build API and XML dependency are not needed here.

Selected: a recorded logbook with an owner, buddies, sites, equipment tanks,
gas definitions, repetitive dives, summaries, gas changes, and pressure channels.
This exercises shared entities, document-wide IDs, mixed-target links, optional
values, choices, and several levels of repeated data. The fixture has two dives,
two gases, two tanks, two pressure readings in one sample, and a gas change.
The second dive has a summary but no samples.

Excluded: planning/table generation, decompression models, medical and training
records, ecology, trips, media, device control, manufacturer details, most
equipment, alarms, rebreather telemetry, extensions, and remaining optional fields.
These add separate domains without improving this ownership/reference experiment.
This subset cannot provide lossless round trips for arbitrary UDDF documents.

## Entities and Zig representations

Notation: `Text = []const u8`; `T? = ?T`; `T[] = []const T`.
All measured scalars use `f32`, matching `xs:float`. Field suffixes give units.
Strings retain their content; XML lexical validation is deferred.

| Zig type | Selected fields and relationships |
| --- | --- |
| `Document` | Required `generator`; optional `diver`, `sites: Site[]`, `mixes: Mix[]`, `groups: RepetitionGroup[]` |
| `Generator` | Required `name: Text`; `version: Text?` |
| `Diver` | Required `owner: Person`; `buddies: Person[]` |
| `Person` | Required `id`, `first_name`, `last_name: Text`; `tanks: Tank[]` represents equipment tanks |
| `Tank` | Required `id`, `name: Text`; `volume_m3: f32?` |
| `Site` | Required `id`, `name: Text`; `geography: Geography?` |
| `Geography` | Required `location: Text`; optional latitude/longitude in degrees and altitude in metres |
| `Mix` | Required `id`, `name: Text`; optional `o2`, `n2`, `he`, `ar`, `h2` fractions; optional limit choice |
| `RepetitionGroup` | Required `id: Text`; one or more `dives: Dive[]` |
| `Dive` | Required `id`, `before`, `after`; `tanks: TankData[]`; optional `samples: Waypoint[]` |
| `InformationBeforeDive` | Required `datetime: Text`; `links: Text[]`; optional positive `dive_number: u32`, surface interval, surface pressure in Pa |
| `InformationAfterDive` | Required greatest depth in metres and duration in seconds; optional lowest temperature in K |
| `TankData` | `links: Text[]`; required initial pressure in Pa; optional final pressure and volume in cubic metres; **no ID** |
| `Waypoint` | Optional depth, elapsed seconds, temperature, heart rate, `switch_mix_ref: Text`; `pressures: TankPressure[]` |
| `TankPressure` | Required pressure in Pa; optional equipment `tank_ref: Text` |

Two tagged unions represent XSD choices: `SurfaceInterval` is `infinity` or
`seconds: i64`; a gas limit is maximum oxygen partial pressure or maximum depth.
The outer optional distinguishes absence from either choice. Oxygen fractions are
0–1, not percentages; heart rate is per second, not beats per minute.

`null` and an empty slice remain distinct for top-level collection sections and
samples. An absent `gasdefinitions` is allowed; a present one needs at least one
mix. `profiledata`, repetition groups, and present samples also need members.
An empty `divesite` is allowed. Equipment-wrapper presence is deliberately not
retained. Required names may be empty because the XSD uses unrestricted strings.

## Constraints and reference semantics

The XSD's `ID_TYPE` requires document-wide `xs:ID` uniqueness. `linkType` requires
`ref: xs:IDREF`, but does not constrain target kinds. The spike collects all IDs
before checking links, so resolution does not depend on declaration order.
It checks duplicate/empty IDs, missing targets, and these domain target kinds:

- Before-dive links: buddies or sites; retain a repeated list, not one site slot.
- Tank-data links: equipment tanks or gas mixes; no artificial one-link limit.
- Sample gas switch: a mix. Pressure reference: an equipment tank.
- A pressure without a reference stays unassigned; no cylinder is inferred.

The model retains missing gas fractions, timezones, and sample values. It does
not insert air, zero fractions, UTC, or surface samples. The test demonstrates
gas-state changes only when an explicit `switchmix` is present.

`Document.validate` checks selected cardinalities and references, plus explicit
**application checks**, not XSD rules: finite nonnegative physical quantities,
coordinate bounds, and gas fractions in [0,1]. Known fractions must not sum above
one; all five supplied fractions must sum to one within `1e-5` absolute tolerance.
Unknown fractions remain unknown. Negative altitude is allowed.

`validateRecordedProfile` is separate: at least three samples, depth and time in
each, an initial (0 s, 0 m) point, and a final surface point. It also requires
strictly increasing times as an experimental policy. Sparse XSD-shaped samples
can pass document validation and fail this complete-profile check.

## Specification conflicts and experiment limits

| Evidence | Treatment in this experiment |
| --- | --- |
| The manual's [schema index](https://www.streit.cc/resources/UDDF/v3.2.3/en/schema.html) links to 3.2.2 | Inspect the separately available 3.2.3 XSD; namespace remains `http://www.streit.cc/uddf/3.2/` |
| [Tank-data prose](https://www.streit.cc/resources/UDDF/v3.2.3/en/tankdata.html) gives it an ID; XSD does not | Equipment `Tank` owns the ID; `TankData` only links to it |
| [Pressure examples](https://www.streit.cc/resources/UDDF/v3.2.3/en/tankpressure.html) use `tankref`; XSD uses `ref` | Model the XSD reference meaning; XML spelling is a later concern |
| [Waypoint prose](https://www.streit.cc/resources/UDDF/v3.2.3/en/waypoint.html) requires depth/time and complete profiles; XSD permits empty waypoints | Preserve optional values; check complete profiles separately |
| [Oxygen prose](https://www.streit.cc/resources/UDDF/v3.2.3/en/o2.html) requires oxygen; XSD makes it optional | Preserve missing oxygen |
| Prose datetime examples use reduced dates/times; XSD uses `xs:dateTime` | Keep the original text; do not convert to an instant |
| `passedtime` is `xs:integer`, though prose examples use decimal notation | Use integer seconds for the experiment |
| Root prose requires section order; XSD uses `xs:all` | No XML ordering policy is implemented |

The official profile example also nests `tankdata` under before-dive information
and omits required summary duration. The XSD makes it a direct child of `dive`,
between before-dive information and samples, followed by after-dive information.
The fixture follows this structure. Example/schema comparisons were inspected,
not run through an XML validator.

Known limits: XML NCName/Unicode rules, datetime syntax, arbitrary-size XML
integers, unknown fields, and full XSD validation are deferred. `u32` dive numbers
and `i64` intervals bound the XSD integer range. No agreement is enforced between
summary and samples, group chronology, or tank links and pressure channels.
No production acceptance/repair policy follows from these experimental checks.

## Ownership and alternatives

The approved **spike-only** choice is `OwnedDocument { arena, value: Document }`.
`init(allocator, source)` deep-copies every selected string and nested slice,
then validates. `errdefer` releases the arena on copying or validation failure;
`deinit` releases it on success. A temporary `StringHashMap(Kind)` uses the backing
allocator and `defer` cleanup. Callers can release the source after `init` returns.

The backing allocator must outlive the owner. Slices and resolved pointers live
until owner cleanup; callers must not free individual fields. Treat the owner as
move-only by convention: Zig does not prevent copies that cause double frees.
No arena allocator interface is stored: it would point to the local arena before
the returned owner moves. Data is read-only through slices after construction.

1. **Document-owned arena (recommended for this experiment):** simple lifetime,
   rollback, and cleanup. Costs a deep copy and retains all memory until cleanup.
2. **Caller-owned borrowed data:** avoids copies, but every backing string and
   slice must outlive access. More lifetime work moves to the caller.

<!-- HUMAN CHECKPOINT REMINDER: Study arena-owned and borrowed-data options
     together before selecting production ownership. Requested by the user. -->

Other pending choices: keep string IDs versus resolve to typed indices (fewer
lookups, but more construction state); retain datetime text versus introduce a
structured date/time (validated operations, but offset/absence semantics need a
design). The spike keeps strings and uses a linear gas lookup. No streaming
strategy is selected; an arena is an experiment in whole-document ownership.

## Executable evidence and checkpoint

Run:

```sh
zig test sandbox/data_model.zig
zig build test
zig fmt --check sandbox/data_model.zig
```

Results on Zig 0.17.0: **8/8 spike tests passed**; existing `zig build test`
and the formatting check also passed.

The eight spike tests cover relationships and gas switching, independent source
lifetime, deep copies, sparse versus complete profiles, invalid values,
cardinalities, duplicate IDs, unresolved/wrong-kind links, and cleanup.
`std.testing.allocator` detects leaks. `checkAllAllocationFailures` injects failure
at each backing allocation for both successful construction and the path that
ends in a duplicate-ID validation error. Arena suballocations are not separate
backing allocations. These checks prove the fixture paths, not general XML
conformance or large-file performance.

The investigation required two design corrections before implementation:
equipment tanks and per-dive tank data must be separate; sparse sample storage
and complete-profile validation must also be separate. No further representation
change was required by the first test run.

Before production work, approve or revise the subset and conformance policy,
reference representation, numeric/date limits, and ownership strategy. In
particular, revisit **both arena-owned and borrowed-data designs together**.
