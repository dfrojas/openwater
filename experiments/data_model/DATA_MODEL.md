# UDDF data-model design record

**Experimental; production design requires approval.** UDDF 3.2.3 spike:
[`sandbox/data_model.zig`](sandbox/data_model.zig).

## Scope

A recorded logbook: owner and buddies, sites, equipment tanks, gases, repetitive
dives, summaries, and samples with gas changes and multiple pressure readings.
This subset exercises shared entities, references, optional values, choices, and
nested collections without modeling all of UDDF. Planning, decompression models,
device control, medical records, trips, and media are intentionally excluded:
they add separate domains without helping evaluate these relationships and lifetimes.
Semantic validation is outside this spike.

## Data model

The [3.2.3 XSD](https://www.streit.cc/resources/UDDF/v3.2.3/schema/uddf_3.2.3.xsd)
provides the experimental structural basis; the manual's
[link descriptions](https://www.streit.cc/resources/UDDF/v3.2.3/en/link.html)
provide domain target meanings.

| Entities | Role and relationships |
| --- | --- |
| `Document`, `Generator` | Document data with required generator metadata and optional people, site, gas, and profile sections |
| `Diver`, `Person` | One owner and repeated buddies share the same person representation; each person can have equipment tanks |
| `Site`, `Geography` | Shared named site with optional location details |
| `Mix` | Shared gas definition, referenced by tank data and sample gas changes |
| `RepetitionGroup`, `Dive` | Groups contain dives; each dive has before/after information, repeated tank data, and optional samples |
| `InformationBeforeDive`, `InformationAfterDive` | Dive context and links to buddies/sites; a summary that can exist without samples |
| `Tank`, `TankData` | Reusable equipment identity versus per-dive pressure/volume data linking to tanks and gases |
| `Waypoint`, `TankPressure` | Sample values, optional gas-switch reference, and repeated pressures with optional tank references |

Modeling rationale:

- **Follow XSD structure provisionally.** The before/after split and repetition
  groups retain UDDF organization rather than introducing independent domain
  concepts. The XSD requires an owner when the diver section exists, at least one
  dive per group, and before/after information with date/time, greatest depth, and
  duration. Optional samples allow summary-only dives. These are structural
  requirements from the source, not claims about runtime validation.
- **Separate tank identity from use.** XSD equipment tanks have IDs; `tankdata`
  has none and belongs directly to a dive. Pressure references identify equipment
  tanks, not per-dive tank data. Gas switches identify mixes, not tanks.
- **Retain reference identity.** String IDs preserve UDDF's document-wide identity
  space. XSD IDREFs do not constrain target kinds, so identity and target-kind
  checks remain explicit and independent of construction. Before-dive and
  tank-data links remain lists; neither is reduced to one target.
- **Preserve absence.** XSD gas fractions and waypoint depth/time are optional.
  Absent sections/samples remain distinct from empty ones. Missing values and
  pressure associations are not inferred, so incomplete records retain their meaning.
- **Preserve mutually exclusive states.** Tagged unions reflect XSD choices:
  a surface interval is infinite or finite, distinct from an absent interval;
  a gas limit specifies maximum oxygen partial pressure or maximum depth, not both.

## Ownership

`Document` holds values and borrowed slices. `OwnedDocument` pairs those data with
an arena and deep-copies all strings and nested slices, so the source can be freed
independently. The backing allocator must outlive the owner; all views into the
owned data expire at `deinit`. The owner must not be duplicated: Zig does not
enforce this ownership rule. **This is an experimental choice; production
ownership remains undecided.**

- **Arena-owned — used in this spike:** one lifetime and simple failure cleanup;
  costs a deep copy and retains all memory until document cleanup.
- **Borrowed data:** avoids copying; the caller must keep all backing storage alive.

## Open decisions

- Data model boundaries. The spike follows the XSD structure. Decide whether OpenWater should expose this representation directly or introduce a separate domain model.

- Reference resolution. String IDs preserve UDDF identity. Evaluate whether typed references or indices should also be used internally for efficient access.

- Memory ownership. The spike uses arena-owned data with deep copies. Evaluate borrowed-data approaches and their implications for lifetimes, parsing, and memory usage before selecting a production strategy.

## Test evidence

The six passing spike tests establish relationships, identity checks, preservation
of absent/empty/sparse data, source-independent copies, and cleanup under injected
allocation failures for the exercised cases. Run `zig test experiments/data_model/data_model.zig`.
