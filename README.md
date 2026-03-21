# Stardew AI

Godot 4.6 farming-life prototype inspired by Stardew Valley.

This repository currently contains a playable vertical slice with a farm loop plus an early merchant, shop, and quest layer:

- top-down movement
- farm, house, and shop scenes with scene transitions
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, harvesting
- shipping bin queueing with next-day settlement and money tracking
- bed-driven next-day flow
- merchant NPC schedule projection and shop interaction
- starter quest chain tied to talking, buying seeds, and shipping produce
- save/load through `user://savegame.json`

## Controls

- `WASD` or arrow keys: move
- `F`: use selected tool or seeds
- `E` or `Space`: interact or harvest
- `Tab` or `I`: toggle inventory panel
- `Q` / `R`: cycle hotbar
- `1-8`: select hotbar slot
- `F5`: save game
- `Esc`: close the shop modal

## Project Layout

- `scenes/main.tscn`: main entry scene
- `scenes/maps/`: farm, house, and shop maps
- `scenes/entities/`: player and NPC projection scenes
- `scripts/autoload/`: global runtime services and gameplay orchestration
- `scripts/world/`: tile palette, map base class, interactables, and shared projection behavior
- `scripts/logic/`: pure logic helpers used by runtime and tests
- `resources/`: item, tool, crop, NPC, schedule, shop, and quest resources
- `tests/test_runner.gd`: headless smoke-style regression tests
- `ARCHITECTURE.md`: current architecture and runtime boundary guide
- `TASKS.md`: current backlog and follow-up work

## Current Slice

The current implementation is intentionally thin but structured for expansion:

- data is resource-driven for items, tools, crops, NPCs, shops, schedules, and quests
- cross-scene state and gameplay orchestration live in autoload services
- player, interactables, and the HUD dispatch user intents through a central action coordinator
- dynamic soil and crop state is stored by `map_id + tile coordinate`
- map ownership is routed through `SceneRouter`, while world save data only stores durable simulation state
- money, shipping, and shop purchasing are owned by `EconomyService`
- map scenes render static tiles plus dynamic soil/crop overlays and NPC projections
- farming, economy, NPC, and quest flows route through dedicated services with a shared action-result envelope
- the project uses runtime-generated placeholder tiles instead of final art

## Verification

The current baseline was verified with:

```bash
godot --headless --path /home/yrd/projects/stardew-ai -s res://tests/test_runner.gd
godot --headless --path /home/yrd/projects/stardew-ai --quit
```

## Docs

- `ARCHITECTURE.md` describes the current runtime boundaries and contribution rules
- `TASKS.md` tracks follow-up work against the current codebase
- `AGENTS.md` gives future agents repo-specific guardrails

## Next Steps

- broaden crops, tools, and shop stock beyond the starter loop
- expand NPC interaction and quest variety beyond the single merchant chain
- add more scenario-level coverage around map transitions, saves, and modal flow on top of the new service tests
- keep growing the slice through the action coordinator instead of reintroducing gameplay flow into scene scripts
