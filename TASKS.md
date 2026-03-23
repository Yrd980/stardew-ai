# Stardew AI Tasks

## Current Baseline

- [x] Initialize the Godot 4.6 project and main scene
- [x] Add farm and house maps with scene transitions
- [x] Implement movement, tool usage, planting, growth, harvesting, sleeping, and save/load
- [x] Store world state in autoload services and render dynamic farm overlays from runtime data
- [x] Add service-layer farm, economy, NPC, and quest boundaries
- [x] Add the shop map and merchant NPC projection
- [x] Add starter shop purchasing flow and next-day shipping settlement
- [x] Add progressive crop/shop content and richer economy persistence
- [x] Add a second quest-giver NPC and broaden the quest chain
- [x] Add save schema v3 defaults for economy progression data
- [x] Move inventory/shop session state behind a dedicated UI session boundary
- [x] Extend progression into tomato and melon content with shipment-value milestones
- [x] Prevent quest turn-ins from consuming item rewards when the inventory cannot receive them

## Current Runtime Direction

- [x] Push more action orchestration out of `scripts/entities/player.gd` and into a central action coordinator
- [x] Standardize result contracts across interactables, NPC interaction, shop actions, sleep flow, and quest completion messaging
- [x] Keep docs aligned whenever service boundaries or gameplay claims change
- [x] Treat real runtime boot as the verification boundary instead of repo-local tests
- [x] Make the default runtime player-only OpenClaw authority instead of human-input authority
- [x] Persist authoritative player actor state in save schema v5
- [x] Export mailbox-based OpenClaw commands, results, snapshot, and room directory from Godot
- [x] Keep NPCs fixed and schedule-owned while the player path moves to OpenClaw control
- [x] Live-verify every currently declared player command against mailbox results, snapshots, and savegame truth

## OpenClaw Runtime Follow-Up

- [ ] Broaden command coverage from the current player loop into more map traversal, farming, and progression scenarios as they ship
- [ ] Tighten snapshot normalization where OpenClaw needs more stable IDs or richer world detail
- [ ] Add higher-signal bridge events for downstream orchestration instead of only per-command result files
- [ ] Decide whether command results should eventually lift snapshot/room_directory payloads out of `directives` into a more explicit transport contract
- [ ] Decide when to prune the older human-oriented entry path completely after the OpenClaw runtime has enough operator confidence

## Phase 1: Farming And Economy Depth

- [x] Add storage and placeable farm infrastructure such as chests and a minimal placeable-object path
- [x] Add crafting plus recipe unlock flow for farm equipment and progression items
- [x] Add fertilizer and crop-quality rules so farming outcomes vary by preparation
- [ ] Add sprinklers or equivalent farm automation after manual crop care still works cleanly
- [x] Add stronger economy sinks such as tool upgrades, recipe/shop unlock costs, or service fees
- [x] Add delivery or claim flow for upgrades/rewards that should not appear instantly
- [ ] Exit criteria: the player can grow, store, craft, improve, and reinvest instead of only buying seeds and shipping produce

## Phase 2: NPC, Social, And Quest Depth

- [ ] Add friendship points and daily conversation tracking
- [ ] Add gift preferences and daily/weekly gift limits
- [ ] Add dialogue pools that branch on friendship, quest progression, weather, and season
- [ ] Add mail delivery for unlocks, thank-you notes, quest follow-ups, and upgrade notices
- [ ] Add bulletin-style repeatable or rotating town quests beyond the authored mainline
- [ ] Add schedule variants that can react to rain, season, or special event days
- [ ] Exit criteria: NPCs feel like persistent residents rather than quest kiosks with one schedule each

## Phase 3: Core Simulation Pressure

- [ ] Add stamina and exhaustion with action costs, low-stamina feedback, and next-day recovery
- [ ] Add day-of-week and calendar structure on top of the current day counter
- [ ] Add seasons and crop seasonality, including out-of-season restrictions or wither rules
- [ ] Add weather generation and tomorrow forecast with rain effects on watering and schedules
- [ ] Add sleep/day-roll integration for stamina, weather, mail, and seasonal transitions in one place
- [ ] Exit criteria: each day requires planning around energy, time, weather, and season rather than only money

## Phase 4: World And Activity Expansion

- [ ] Add authored non-farm destinations such as town, forest, beach, and mine-adjacent spaces
- [ ] Add a forage loop with map-specific seasonal pickups
- [ ] Add a fishing loop with location-aware catch tables and time/weather hooks
- [ ] Add a mining loop with breakable nodes, ore progression, and reward pacing
- [ ] Keep map scripts projection-thin by routing all new actions through `ActionCoordinator` and service-owned state
- [ ] Exit criteria: the player has meaningful off-farm reasons to travel through multiple maps each day

## Phase 5: Long-Tail Stardew Systems

- [ ] Add buildings, barns/coops, and upgrade-driven farm layout progression
- [ ] Add animals, feed/care flow, and animal-produced goods
- [ ] Add cooking and kitchen progression tied to crops, fish, and animal outputs
- [ ] Add house upgrades and interior progression
- [ ] Add festivals, event days, or other calendar-driven special content
- [ ] Add a town restoration, community-board, or other long-term meta-progression track
- [ ] Exit criteria: the game has medium- and long-horizon goals beyond the first profitable crop loops

## Verification Expectations

- [ ] Keep using real runtime verification instead of repo-local tests unless the user explicitly changes that boundary
- [ ] Re-run `godot --headless --path /home/yrd/projects/stardew-ai --quit` after each substantial backend phase
- [ ] Re-run `timeout 5 godot --headless --path /home/yrd/projects/stardew-ai` after each substantial backend phase
- [ ] Update `README.md` and `ARCHITECTURE.md` in the same change that shifts runtime boundaries or shipped behavior
