# Stardew AI Architecture

Godot 4.6 farming-life prototype inspired by Stardew Valley.

## Baseline

The repo currently reflects two implementation stages:

- commit 1 established the farm-loop slice: farm and house maps, till/water/plant/grow/harvest/ship, save/load, and headless logic tests
- commit 2 expanded the runtime with service-layer farming, economy, NPC, and quest boundaries, plus a shop map, merchant schedule, starter quest chain, shipping settlement, and save schema updates

The codebase should keep building on the second-stage structure rather than treating the repo as a blank farming prototype.

## Current Gameplay Slice

- top-down movement across farm, house, and shop maps
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, and harvesting
- shipping bin queueing with next-day settlement
- merchant NPC projection driven by daily schedule data
- shop modal with starter seed purchases and daily stock limits
- starter quest chain tied to talking, buying, and shipping
- save/load through `user://savegame.json` with save schema v2 migration defaults

## Layer Model

### Autoload Services

Autoloads own long-lived runtime state and most gameplay orchestration.

- `GameState`: resource loading, input map bootstrap, starting-state bootstrap, and content lookup
- `SceneRouter`: current map ownership and map-change requests
- `ClockService`: passive time flow, sleeping, day advancement, next-day settlement trigger
- `InventoryService`: inventory slots, selection, stacking mutations
- `WorldState`: soil, crop, and per-map player position state
- `SaveManager`: compose, serialize, and load the top-level durable save snapshot
- `FarmService`: farming actions and result/event dictionaries
- `EconomyService`: money, shipping queue, shipment settlement, and shop purchasing
- `NpcService`: schedule-driven NPC projection state and interaction results
- `QuestService`: quest activation, progress tracking, completion, and rewards
- `ActionCoordinator`: user-intent entrypoint that applies shared side effects like time, map changes, save triggers, messages, and shop directives

### Logic

`scripts/logic/` is the functional core when possible.

- `crop_logic.gd`: crop stage and next-day growth calculations
- `inventory_logic.gd`: stack and slot mutations
- `save_codec.gd`: save payload defaults and migration helpers

Keep calculations here when they do not need live scene nodes or autoload state mutation.

### Data and Resources

`scripts/data/` defines resource schemas. `resources/` contains authored gameplay content.

- items, tools, and crops
- NPC definitions and schedules
- shop stock data
- quest chain definitions

Gameplay expansion should prefer new data resources over hardcoding content in scene or entity scripts.

### Scene, Map, Entity, and UI Scripts

These scripts should stay thin and projection-oriented.

- `scripts/world/map_scene.gd` renders static map structure plus dynamic soil/crop overlays and NPC projections
- `scripts/maps/*.gd` define map-specific layout, spawn points, and interactables
- `scripts/entities/player.gd` handles movement, targeting, and intent dispatch into `ActionCoordinator`
- `scripts/entities/npc_projection.gd` projects NPC state and exposes an interaction request
- `scripts/ui/hud.gd` renders status, quests, inventory, and shop state while sending purchase intents through `ActionCoordinator`
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

### Communication

- prefer direct Godot signals between known services
- do not introduce a global event bus unless the current signal graph becomes difficult to reason about
- avoid deep node traversal; use signals, references, or scene setup

### Action Results

Gameplay actions should prefer the current dictionary result shape already used by services:

```gdscript
{
	"success": true,
	"message": "Planted Parsnip Seeds.",
	"time_cost": 5,
	"events": [],
	"directives": {}
}
```

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
- current tests now cover logic helpers plus architecture-critical service and coordinator behavior, but they are still headless smoke tests rather than full gameplay scenario coverage
- the game currently centers on one crop, one merchant, one shop, and a starter quest chain
- stamina, weather, seasons, and broader world simulation are not implemented yet

## Verified Commands

```bash
godot --headless --path /home/yrd/projects/stardew-ai -s res://tests/test_runner.gd
godot --headless --path /home/yrd/projects/stardew-ai --quit
```
