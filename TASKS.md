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

## Current Runtime Direction

- [x] Push more action orchestration out of `scripts/entities/player.gd` and into a central action coordinator
- [x] Standardize result contracts across interactables, NPC interaction, shop actions, sleep flow, and quest completion messaging
- [x] Keep docs aligned whenever service boundaries or gameplay claims change
- [x] Treat real runtime boot as the verification boundary instead of repo-local tests

## Next Expansion Work

- [ ] Add broader simulation systems like stamina, weather, and seasons
- [ ] Expand authored maps once the current runtime loop stays stable in real play
- [ ] Add more economy-facing sinks, unlocks, and long-tail progression after the current shipping loop is balanced
- [ ] Keep new features flowing through `ActionCoordinator` so scene scripts stay projection-first
