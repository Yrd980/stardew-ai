# Stardew AI

Godot 4.6 farming-life prototype inspired by Stardew Valley.

This repository currently ships a playable backend-first vertical slice with a broader farm, shop, and quest loop:

- top-down movement across farm, house, and shop maps
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, harvesting, and shipping
- next-day settlement with money tracking and shipment history
- merchant and field-planner NPC schedule projection
- progressive shop stock that unlocks as quest milestones are completed
- quest chains tied to talking, buying seeds, harvesting produce, shipping crops, regrowing vines, and higher-value overnight shipments
- save/load through `user://savegame.json`

## Stardew Target

The project goal is no longer just a farming prototype. The intended destination is a broader Stardew-like simulation with:

- deeper farm management through upgrades, automation, storage, crafting, and produce quality
- stronger NPC life-sim systems through friendship, gifting, mail, schedule variation, and repeatable town quests
- day-to-day simulation pressure through stamina, weather, calendar flow, and seasonal crop rules
- a larger world loop through town, forage, fishing, mining, and other authored destinations beyond the starter farm/shop slice
- longer-tail progression through buildings, animals, cooking, house upgrades, festivals, and a town-scale restoration or shared-goal arc

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
- quest turn-ins protect item rewards instead of silently consuming them when the inventory is full
- NPC projection is schedule-derived at runtime instead of persisted directly
- farming, economy, NPC, and quest flows route through dedicated services with a shared action-result envelope
- the project uses runtime-generated placeholder tiles instead of final art

## Current Progression

- Mae's stock now steps from parsnips into potatoes, cauliflower, blueberries, tomatoes, and melons
- Rowan's field-planning quest chain now continues past first regrowth into repeat-yield tomato work and premium melon deliveries
- overnight shipping progress now tracks both item counts and higher-value settlement milestones

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

## Docs

- `ARCHITECTURE.md` describes the current runtime boundaries and contribution rules
- `TASKS.md` tracks follow-up work against the current codebase
- `AGENTS.md` gives future agents repo-specific guardrails

## Next Steps

- keep all future feature growth flowing through `ActionCoordinator` instead of reintroducing gameplay flow into scene scripts
- use the current shipped slice as the baseline for farming/economy and social-system expansion rather than restarting the architecture
- treat root docs as the authoritative roadmap: `README.md` for shipped status + goals, `ARCHITECTURE.md` for boundaries, and `TASKS.md` for ordered delivery
