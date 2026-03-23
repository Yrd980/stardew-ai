# Stardew AI Architecture

Godot 4.6 farming-life prototype inspired by Stardew Valley.

## Baseline

The repo currently reflects three implementation stages:

- commit 1 established the farm-loop slice: farm and house maps, till/water/plant/grow/harvest/ship, and save/load
- commit 2 expanded the runtime with service-layer farming, economy, NPC, and quest boundaries, plus a shop map, merchant schedule, starter quest chain, shipping settlement, and save schema updates
- commit 3 broadened the shipped slice with additional crops, progressive shop stock, a second NPC quest giver, UI session state ownership, and richer economy persistence

The codebase should keep building on the service/resource structure rather than treating the repo as a blank farming prototype.

## Current Gameplay Slice

- top-down movement across farm, house, and shop maps
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, harvesting, and shipping
- merchant and field-planner NPC projection driven by daily schedules
- shop stock that unlocks as quest milestones are completed
- quest chains tied to talking, buying, harvesting, shipping, and repeat-harvest crop progression
- save/load through `user://savegame.json` with save schema v3 migration defaults

## Layer Model

### Autoload Services

Autoloads own long-lived runtime state and most gameplay orchestration.

- `GameState`: resource loading, input map bootstrap, starting-state bootstrap, and content lookup
- `SceneRouter`: current map ownership and map-change requests
- `ClockService`: passive time flow, sleeping, day advancement, next-day settlement trigger
- `InventoryService`: inventory slots, selection, stacking mutations
- `WorldState`: soil, crop, regrowth, and per-map player position state
- `SaveManager`: compose, serialize, and load the top-level durable save snapshot
- `FarmService`: farming actions and result/event dictionaries
- `EconomyService`: money, shipping queue, shipment settlement, shipment history, and shop purchasing/unlock rules
- `NpcService`: schedule-driven NPC projection state and interaction results
- `QuestService`: quest activation, progress tracking, completion, and rewards
- `ActionCoordinator`: user-intent entrypoint that applies shared side effects like time, map changes, save triggers, messages, and shop directives
- `UiSessionService`: inventory/shop session ownership so HUD stays a projection layer

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
- quest chain definitions

Gameplay expansion should prefer new data resources over hardcoding content in scene or entity scripts.

### Scene, Map, Entity, and UI Scripts

These scripts should stay thin and projection-oriented.

- `scripts/world/map_scene.gd` renders static map structure plus dynamic soil/crop overlays and NPC projections
- `scripts/maps/*.gd` define map-specific layout, spawn points, and interactables
- `scripts/entities/player.gd` handles movement, targeting, and intent dispatch into `ActionCoordinator`
- `scripts/entities/npc_projection.gd` projects NPC state and exposes an interaction request
- `scripts/ui/hud.gd` renders status, quests, inventory, and shop state from service/session authority while sending purchase intents through `ActionCoordinator`
- interactables should build action requests, not hide gameplay side effects or direct service orchestration

## State and Flow Rules

### State Ownership

- long-lived world and gameplay state belongs in autoload services
- map scenes are projections of state, not the source of truth
- authored content belongs in resources, not in gameplay controllers
- `SceneRouter` owns the current map id
- `WorldState` owns durable world simulation plus saved player positions, not navigation state
- `NpcService` derives runtime NPC projection state from schedule data and current time; that projection is not persisted
- `EconomyService` owns money and other economy-facing save data
- `UiSessionService` owns transient inventory/shop session state, not HUD widgets

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

## Architectural Constraints

- Keep `player.gd`, map scripts, and interactables thin.
- Prefer adding behavior to services before adding more orchestration to entity scripts.
- Keep pure or near-pure calculations in `scripts/logic/`.
- Prefer data-driven resources for content.
- Do not refactor this repo toward ECS-lite just for pattern purity.
- Do not add pattern-heavy abstractions unless there is a concrete maintenance problem they solve.

## Key Runtime Entry Points

- `scripts/main.gd`: boots save or new game and swaps maps
- `scripts/autoload/action_coordinator.gd`: central user-action boundary for player, shop, NPC, and interactable intents
- `scripts/autoload/ui_session_service.gd`: transient inventory/shop session authority
- `scripts/entities/player.gd`: reads input, computes target context, and dispatches intents
- `scripts/autoload/world_state.gd`: soil/crop state and next-day processing
- `scripts/autoload/farm_service.gd`: farming action entrypoints
- `scripts/autoload/economy_service.gd`: shipping and purchasing entrypoints
- `scripts/autoload/npc_service.gd`: NPC schedule projection and interaction state
- `scripts/autoload/quest_service.gd`: quest tracking and reward flow
- `scripts/world/map_scene.gd`: shared map rendering and dynamic projection refresh
- `scripts/ui/hud.gd`: status, quest text, inventory, shop modal rendering, and action-coordinator signal handling

## Known Limits

- placeholder visuals are still used throughout the project
- the game is still a compact vertical slice even after adding more crops, progression gates, and a second quest-giver NPC
- stamina, weather, seasons, and broader world simulation are not implemented yet

## Verified Commands

    godot --path /home/yrd/projects/stardew-ai
    godot --headless --path /home/yrd/projects/stardew-ai --quit
    timeout 3 godot --headless --path /home/yrd/projects/stardew-ai
