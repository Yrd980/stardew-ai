# Stardew AI Architecture

Godot 4.6 farming-life prototype inspired by Stardew Valley.

The current default runtime is a player-only OpenClaw AI-native authority loop. NPCs remain fixed schedule-driven projections.

## Baseline

The repo currently reflects three implementation stages:

- commit 1 established the farm-loop slice: farm and house maps, till/water/plant/grow/harvest/ship, and save/load
- commit 2 expanded the runtime with service-layer farming, economy, NPC, and quest boundaries, plus a shop map, merchant schedule, starter quest chain, shipping settlement, and save schema updates
- commit 3 broadened the shipped slice with additional crops, progressive shop stock, a second NPC quest giver, UI session state ownership, and richer economy persistence
- the current runtime keeps those systems but moves the player control path to OpenClaw-facing actor authority and mailbox commands

The codebase should keep building on the service/resource structure rather than treating the repo as a blank farming prototype.

## Target Shape

The intended destination is a fuller Stardew-like life sim, but it should still grow out of the current service/resource architecture instead of collapsing back into scene-owned gameplay code.

- farming remains the anchor loop, but expands into automation, crafting, quality, seasonality, and weather-aware planning
- NPC systems expand from schedule projection into friendship, gifts, mail, richer quest chains, and event-day variation
- world progression expands from farm/house/shop into authored destination maps and activity-specific services such as fishing and mining
- long-tail progression eventually includes buildings, animals, cooking, festivals, and a town-level restoration or shared-goal arc

## Current Runtime Slice

- OpenClaw controls the player through semantic mailbox commands
- farm, house, and shop maps stay thin projections over service-owned state
- tilling, watering, planting, overnight crop growth, harvesting, shipping, crafting, delivery claims, and storage remain service-owned rules
- merchant and field-planner NPCs remain fixed schedule-driven projections
- save/load flows through `user://savegame.json` with save schema v5 actor state
- authoritative snapshot and room-directory exports live under `user://openclaw_bridge/`

## Layer Model

### Autoload Services

Autoloads own long-lived runtime state and most gameplay orchestration.

- `GameState`: resource loading, content lookup, map-scene registry, and starting-state bootstrap
- `SceneRouter`: current map ownership, loaded-map reference, and map-change requests
- `ClockService`: passive time flow, sleeping, day advancement, next-day settlement trigger
- `InventoryService`: inventory slots, selection, quality-aware stacking mutations
- `WorldState`: soil, crop, regrowth, placed objects, chest contents, and per-map player position state
- `ActorService`: authoritative player actor map/cell/world-position/facing state
- `SaveManager`: compose, serialize, and load the top-level durable save snapshot
- `FarmService`: farming actions and result/event dictionaries
- `EconomyService`: money, shipping queue, shipment settlement, shipment history, and shop purchasing/unlock rules
- `NpcService`: schedule-driven NPC projection state and interaction results
- `QuestService`: quest activation, progress tracking, completion, and rewards, including reward-capacity checks before a turn-in finalizes
- `ActionCoordinator`: semantic gameplay command boundary that applies shared side effects like time, map changes, save triggers, messages, and shop directives
- `UiSessionService`: inventory, shop, chest, crafting, and delivery session ownership so HUD stays a projection layer
- `CraftingService`: recipe availability, crafting outputs, and placeable-object requests handed off into world state
- `MailService`: pending delivery claims for delayed unlocks
- `AgentSnapshotService`: authoritative player snapshot and room-directory exporter
- `AgentCommandService`: player-only OpenClaw command dispatcher
- `AgentBridgeService`: local mailbox bridge that polls commands and writes results, snapshots, and room directories

### Logic

`scripts/logic/` is the functional core when possible.

- `crop_logic.gd`: crop stage and next-day growth calculations
- `inventory_logic.gd`: stack and slot mutations
- `save_codec.gd`: save payload defaults and migration helpers

Keep calculations here when they do not need live scene nodes or autoload state mutation.

### Data and Resources

`scripts/data/` defines resource schemas. `resources/` contains authored gameplay content.

- items and crops
- NPC definitions and schedules
- shop stock data with progression gates
- quest chain definitions for item-count and shipment-value milestones
- recipe and placeable-object resources for Phase 1 farming depth

Gameplay expansion should prefer new data resources over hardcoding content in scene or entity scripts.

### Scene, Map, Entity, and UI Scripts

These scripts should stay thin and projection-oriented.

- `scripts/world/map_scene.gd` renders static map structure plus dynamic soil/crop/placeable overlays, NPC projections, and room-directory descriptors
- `scripts/maps/*.gd` define map-specific layout, spawn points, and interactables
- `scripts/entities/player.gd` projects the player actor state owned by `ActorService`
- `scripts/entities/npc_projection.gd` projects NPC state and exposes an interaction request
- `scripts/ui/hud.gd` renders status, quests, inventory, and shop state from service/session authority; it is no longer the authority command path
- interactables should build action requests, not hide gameplay side effects or direct service orchestration

## State and Flow Rules

### State Ownership

- long-lived world and gameplay state belongs in autoload services
- map scenes are projections of state, not the source of truth
- authored content belongs in resources, not in gameplay controllers
- `SceneRouter` owns the current map id and loaded map scene reference
- `ActorService` owns the authoritative player actor transform and facing
- `WorldState` owns durable world simulation plus mirrored saved player positions for compatibility
- `NpcService` derives runtime NPC projection state from schedule data and current time; that projection is not persisted
- `EconomyService` owns money and other economy-facing save data
- `UiSessionService` owns transient inventory/shop session state, not HUD widgets
- `CraftingService` owns recipe unlock state and crafting outputs
- `MailService` owns pending delivery claims for delayed unlocks
- future durable simulation state should follow the same pattern: one save section per long-lived service when a subsystem actually ships

### Communication

- prefer direct Godot signals between known services
- do not introduce a global event bus unless the current signal graph becomes difficult to reason about
- avoid deep node traversal; use signals, references, or scene setup

### Action Results

Gameplay actions should prefer the shared dictionary result shape:

    {
        "success": true,
        "message": "Planted Parsnip Seeds.",
        "time_cost": 5,
        "events": [],
        "directives": {}
    }

Feature-specific fields are acceptable when the caller genuinely needs them, but the base result shape should stay recognizable across services. UI-facing follow-up like shop opening should route through `directives` rather than ad hoc top-level fields.

OpenClaw-facing command results reuse the same shape and attach command metadata plus semantic fields such as `applied_steps`, `cell`, `snapshot`, or `room_directory` in `directives` when needed.

The current movement contract is partial-progress rather than all-or-nothing: the runtime advances step by step until blocked, then returns the final reachable state and applied progress.

## OpenClaw Bridge

The player-only bridge is a filesystem mailbox under `user://openclaw_bridge/`.

- `commands/*.json`: incoming command envelopes shaped like `{command_id, actor_id, type, args}`
- `results/*.json`: normalized command results
- `snapshot.json`: latest authoritative runtime snapshot
- `room_directory.json`: stable map/interactable directory
- `events.jsonl`: append-only result stream

V1 does not expose generic UI index commands. The supported command families are semantic player actions such as movement, tools, planting, harvesting, talking, buying, shipping, crafting, delivery claims, container mutations, and save.

V1 also keeps NPC control out of the bridge on purpose. NPCs remain fixed schedule-driven service projections, and the bridge may query or talk to them but does not own their runtime state.

## Architectural Constraints

- Keep `player.gd`, map scripts, and interactables thin.
- Prefer adding behavior to services before adding more orchestration to entity scripts.
- Keep pure or near-pure calculations in `scripts/logic/`.
- Prefer data-driven resources for content.
- Do not refactor this repo toward ECS-lite just for pattern purity.
- Do not add pattern-heavy abstractions unless there is a concrete maintenance problem they solve.

## Key Runtime Entry Points

- `scripts/openclaw_runtime_main.gd`: boots the OpenClaw runtime, loads the active map, and projects actor-owned state
- `scripts/autoload/action_coordinator.gd`: central gameplay command boundary for player, shop, NPC, and interactable intents
- `scripts/autoload/actor_service.gd`: authoritative player actor state
- `scripts/autoload/agent_command_service.gd`: player command dispatch
- `scripts/autoload/agent_snapshot_service.gd`: snapshot and room-directory export
- `scripts/autoload/agent_bridge_service.gd`: mailbox polling and result writing
- `scripts/autoload/ui_session_service.gd`: transient inventory/shop session authority
- `scripts/autoload/crafting_service.gd`: recipe availability and crafting outputs
- `scripts/autoload/mail_service.gd`: next-day delivery queue and claim flow
- `scripts/entities/player.gd`: player projection node
- `scripts/autoload/world_state.gd`: soil/crop state and next-day processing
- `scripts/autoload/farm_service.gd`: farming action entrypoints
- `scripts/autoload/economy_service.gd`: shipping and purchasing entrypoints
- `scripts/autoload/npc_service.gd`: NPC schedule projection and interaction state
- `scripts/autoload/quest_service.gd`: quest tracking and reward flow
- `scripts/world/map_scene.gd`: shared map rendering and dynamic projection refresh for crops, placeables, and chest interactables
- `scripts/ui/hud.gd`: observer HUD for status and service state

## Known Limits

- placeholder visuals are still used throughout the project
- the game is still a compact vertical slice even after adding more crops, progression gates, shipment-value progression, and a second quest-giver NPC
- only the player is OpenClaw-controlled today; NPCs remain fixed schedule projections
- sprinklers/automation, stamina, weather, calendar/seasonality, friendship mail, fishing, mining, animals, festivals, and broader world simulation are not implemented yet

## Verified Commands

    godot --path /home/yrd/projects/stardew-ai
    godot --headless --path /home/yrd/projects/stardew-ai --quit
    timeout 5 godot --headless --path /home/yrd/projects/stardew-ai
