# Stardew AI Tasks

## Current Baseline

- [x] Initialize the Godot 4.6 project and main scene
- [x] Add farm and house maps with scene transitions
- [x] Implement movement, tool usage, planting, growth, harvesting, sleeping, and save/load
- [x] Store world state in autoload services and render dynamic farm overlays from runtime data
- [x] Add service-layer farm, economy, NPC, and quest boundaries
- [x] Add the shop map and merchant NPC projection
- [x] Add starter shop purchasing flow and next-day shipping settlement
- [x] Add the starter quest chain tied to talking, buying seeds, and shipping produce
- [x] Add save schema v2 defaults for economy, NPC, and quest state
- [x] Add headless smoke tests for logic, save codec, and resource contracts

## Next Architecture Tightening

- [x] Push more action orchestration out of `scripts/entities/player.gd` and into a central action coordinator
- [x] Standardize result contracts across interactables, NPC interaction, shop actions, and sleep flow
- [x] Add focused tests for `FarmService`, `EconomyService`, `NpcService`, and the action-coordinator boundary
- [x] Keep docs aligned whenever service boundaries or gameplay claims change

## Next Boundary Work

- [ ] Add richer scenario tests around map transitions, sleeping, and save/load recovery through `ActionCoordinator`
- [ ] Move inventory toggle and modal-open state behind a clearer UI session boundary if more modals appear
- [ ] Decide whether quest completion/reward responses should also adopt the full action-result envelope
- [ ] Keep new features flowing through `ActionCoordinator` so scene scripts stay projection-first

## Next Gameplay Expansion

- [ ] Add more crops, tools, and shop stock beyond the parsnip starter loop
- [ ] Expand NPC interaction beyond the single merchant flow
- [ ] Broaden quests beyond the three-step starter chain
- [ ] Add richer economy and progression hooks on top of the current shipping loop
- [ ] Introduce broader simulation systems like stamina, weather, or seasons only after current service boundaries stay clean
