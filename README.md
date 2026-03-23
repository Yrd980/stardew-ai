# Stardew AI

Godot 4.6 farming-life prototype inspired by Stardew Valley.

This repository currently ships a playable backend-first vertical slice with a broader farm, shop, and quest loop:

- top-down movement across farm, house, and shop maps
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, harvesting, and shipping
- next-day settlement with money tracking and shipment history
- merchant and field-planner NPC schedule projection
- progressive shop stock that unlocks as quest milestones are completed
- quest chains tied to talking, buying seeds, harvesting produce, shipping crops, and regrowing berries
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
- `scripts/logic/`: pure logic helpers used by runtime services and save migration
- `resources/`: item, crop, NPC, schedule, shop, and quest resources
- `ARCHITECTURE.md`: current architecture and runtime boundary guide
- `TASKS.md`: current backlog and follow-up work

## Current Slice

The current implementation is intentionally thin in presentation but structured for expansion:

- data is resource-driven for items, crops, NPCs, shops, schedules, and quests
- cross-scene state and gameplay orchestration live in autoload services
- player, interactables, and the HUD dispatch user intents through a central action coordinator
- UI session state is centralized so inventory/shop flow is not owned only by the HUD
- dynamic soil and crop state is stored by `map_id + tile coordinate`
- map ownership is routed through `SceneRouter`, while world save data only stores durable simulation state
- money, shipping, stock unlocks, and shipment history are owned by `EconomyService`
- NPC projection is schedule-derived at runtime instead of persisted directly
- farming, economy, NPC, and quest flows route through dedicated services with a shared action-result envelope
- the project uses runtime-generated placeholder tiles instead of final art

## Verification

The current baseline is verified through real runtime boot:

    godot --path /home/yrd/projects/stardew-ai
    godot --headless --path /home/yrd/projects/stardew-ai --quit
    timeout 3 godot --headless --path /home/yrd/projects/stardew-ai

## Docs

- `ARCHITECTURE.md` describes the current runtime boundaries and contribution rules
- `TASKS.md` tracks follow-up work against the current codebase
- `AGENTS.md` gives future agents repo-specific guardrails

## Next Steps

- keep growing the slice through `ActionCoordinator` instead of reintroducing gameplay flow into scene scripts
- deepen progression with more economy milestones, authored quest chains, and additional content
- expand into broader simulation systems like stamina, weather, and seasons only after the current runtime loop stays stable in real play
