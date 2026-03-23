# Stardew AI

Godot 4.6 farming-life prototype inspired by Stardew Valley.

This repository now boots as a player-only OpenClaw AI-native authority runtime. Godot owns the rules and save truth; OpenClaw drives the player through a local mailbox bridge.

Current shipped runtime surface:

- player actor authority owned by `ActorService`
- fixed NPC projections still owned by `NpcService`
- semantic player commands instead of HUD/index commands
- authoritative snapshot and room-directory exports under `user://openclaw_bridge/`
- farm, house, and shop maps with farming, economy, quest, crafting, storage, delivery, and save flows
- save/load through `user://savegame.json` with actor state persisted in save schema v5

## Stardew Target

The project goal is no longer just a farming prototype. The intended destination is a broader Stardew-like simulation with:

- deeper farm management through upgrades, automation, storage, crafting, and produce quality
- stronger NPC life-sim systems through friendship, gifting, mail, schedule variation, and repeatable town quests
- day-to-day simulation pressure through stamina, weather, calendar flow, and seasonal crop rules
- a larger world loop through town, forage, fishing, mining, and other authored destinations beyond the starter farm/shop slice
- longer-tail progression through buildings, animals, cooking, house upgrades, festivals, and a town-scale restoration or shared-goal arc

## OpenClaw Runtime

Default entry:

- `scenes/openclaw_runtime.tscn`

Bridge mailbox:

- `user://openclaw_bridge/commands/*.json`: incoming commands
- `user://openclaw_bridge/results/*.json`: per-command results
- `user://openclaw_bridge/snapshot.json`: latest authoritative snapshot
- `user://openclaw_bridge/room_directory.json`: stable map and interactable directory
- `user://openclaw_bridge/events.jsonl`: command result stream

V1 player commands:

- `hello`
- `get_snapshot`
- `get_room_directory`
- `move {direction, steps}`
- `face {direction}`
- `use_tool {tool_id, target_cell}`
- `plant_seed {seed_item_id, target_cell}`
- `apply_fertilizer {item_id, target_cell}`
- `harvest {target_cell}`
- `place_object {item_id, target_cell}`
- `talk_to {npc_id}`
- `buy_item {shop_id, item_id, quantity}`
- `ship_inventory_slot {slot_index}`
- `sleep`
- `craft_recipe {recipe_id}`
- `claim_delivery`
- `container_store {object_id, inventory_slot_index, amount}`
- `container_take {object_id, container_slot_index, amount}`
- `save_game`

Important command notes:

- `actor_id` is currently always `player`
- `move {direction, steps}` is partial-progress: it walks until blocked and reports applied progress in the result
- `buy_item`, `sleep`, `craft_recipe`, `claim_delivery`, and container commands require the player to already be adjacent to the relevant NPC or static target
- NPCs are visible in snapshots and room context, but they are not OpenClaw-controlled actors in v1

## Project Layout

- `scenes/openclaw_runtime.tscn`: default OpenClaw runtime scene
- `scenes/main.tscn`: older human-oriented entry scene kept only as a reference path
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
- `ActorService` is now the authority source for the player actor instead of `CharacterBody2D`
- `ActionCoordinator` serves as the semantic gameplay command boundary for OpenClaw-facing commands
- `AgentSnapshotService` and `AgentBridgeService` export runtime truth without duplicating gameplay rules
- dynamic soil, crop, placeable, and chest state is still stored by `map_id + tile coordinate`
- money, shipping, stock unlocks, and shipment history are owned by `EconomyService`
- recipe unlocks and delayed delivery claims flow through `CraftingService` and `MailService`
- NPC projection remains fixed and schedule-derived at runtime instead of being OpenClaw-controlled
- the project uses runtime-generated placeholder tiles instead of final art

## Current Progression

- Mae's stock now steps from parsnips into potatoes, cauliflower, blueberries, tomatoes, and melons
- Rowan's field-planning quest chain now continues past first regrowth into repeat-yield tomato work and premium melon deliveries
- overnight shipping progress now tracks both item counts and higher-value settlement milestones
- Mae now sells raw lumber/sap plus recipe permits that arrive through the farm delivery box on the next day
- workbench recipes currently cover a basic chest, starter fertilizer, and a later quality-fertilizer unlock

## Planned Delivery Order

- Phase 1: deepen farming and economy with storage, crafting, fertilizer, sprinklers, quality, and stronger money sinks
- Phase 2: deepen NPC and social play with friendship, gifts, mail, richer dialogue, and bulletin-style quests
- Phase 3: add stamina, weather, calendar, and seasonality so the day loop has real planning pressure
- Phase 4: expand authored destinations and activity loops such as forage, fishing, and mining while keeping scenes thin
- Phase 5: add long-tail Stardew systems such as animals, cooking, festivals, house upgrades, and town restoration

## Verification

The current baseline is verified through real runtime boot:

    godot --path /home/yrd/projects/stardew-ai
    godot --headless --path /home/yrd/projects/stardew-ai --quit
    timeout 5 godot --headless --path /home/yrd/projects/stardew-ai

Bridge verification can also use live mailbox commands while the headless runtime is running. The durable save truth remains:

    /home/yrd/.local/share/godot/app_userdata/Stardew AI/savegame.json

Minimal live verification loop:

    godot --headless --path /home/yrd/projects/stardew-ai

Then write command JSON files into:

    /home/yrd/.local/share/godot/app_userdata/Stardew AI/openclaw_bridge/commands/

And inspect:

    /home/yrd/.local/share/godot/app_userdata/Stardew AI/openclaw_bridge/results/
    /home/yrd/.local/share/godot/app_userdata/Stardew AI/openclaw_bridge/snapshot.json
    /home/yrd/.local/share/godot/app_userdata/Stardew AI/savegame.json

## Docs

- `ARCHITECTURE.md` describes the current runtime boundaries and contribution rules
- `TASKS.md` tracks follow-up work against the current codebase
- `AGENTS.md` gives future agents repo-specific guardrails

## Next Steps

- keep all future feature growth flowing through `ActionCoordinator`, `ActorService`, and service-owned state instead of reintroducing gameplay flow into scene scripts
- expand the OpenClaw command surface from the current player-only bridge without cloning rules into adapters
- treat root docs as the authoritative roadmap: `README.md` for shipped status + goals, `ARCHITECTURE.md` for boundaries, and `TASKS.md` for ordered delivery
