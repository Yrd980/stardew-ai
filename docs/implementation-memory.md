# Implementation Memory

## Session Goal

Create the first Godot 4 version of a Stardew-like project from an empty repository, using the bundled \`godot-docs/\` checkout as local reference material while keeping the playable scope centered on the farm loop.

## Delivered In This Session

- initialized a Godot 4.6 project with autoload services and a main scene
- added a farm map and a house map with transition doors
- implemented a controllable player with hotbar input and interaction flow
- added core farming actions: till, water, plant, sleep, grow, harvest, ship
- added JSON save/load through \`user://savegame.json\`
- added data resources for starter items, tools, and one crop
- added headless logic tests for inventory, crop progression, and save codec
- used generated placeholder tile art so the prototype is self-contained

## Important Architectural Decisions

- \`TileMapLayer\` is used everywhere instead of deprecated \`TileMap\`
- global runtime state is split into autoload services:
  \`GameState\`, \`SceneRouter\`, \`ClockService\`, \`InventoryService\`, \`WorldState\`, \`SaveManager\`
- map-specific dynamic state is stored in dictionaries keyed by \`map_id\` and \`"x,y"\`
- static world presentation is scene-based, while farmable soil and crops are rebuilt from runtime state
- helper logic is isolated in \`scripts/logic/\` so it can be tested headlessly
- \`godot-docs/\` is treated as a local reference checkout and is ignored by git

## Starter Gameplay State

- starting money: \`250g\`
- starting inventory:
  - hoe
  - watering can
  - 15 parsnip seeds
- maps:
  - \`farm\`
  - \`house\`
- crop:
  - \`parsnip_crop\`
  - 4-stage growth over 4 watered days

## Key Runtime Entry Points

- \`scripts/main.gd\`: boots save/new game and swaps maps
- \`scripts/entities/player.gd\`: player input, tool use, planting, harvesting, interaction
- \`scripts/autoload/world_state.gd\`: soil/crop state and next-day processing
- \`scripts/autoload/inventory_service.gd\`: hotbar/inventory mutations
- \`scripts/world/map_scene.gd\`: shared map rendering and dynamic layer refresh

## Known Limits

- placeholder visuals only
- no NPCs, shops, quests, stamina, weather, or seasons yet
- no editor-authored tileset pipeline yet because this slice builds tiles procedurally
- no remote repository was configured at implementation time

## Verified Commands

\`\`\`bash
godot --headless --path /home/yrd/projects/stardew-ai -s res://tests/test_runner.gd
godot --headless --path /home/yrd/projects/stardew-ai --quit
\`\`\`
