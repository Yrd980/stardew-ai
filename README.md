# Stardew AI

Godot 4.6 farming-life prototype inspired by Stardew Valley.

This repository currently contains a playable vertical slice focused on the farm loop:

- top-down movement
- farm and house scenes with scene transitions
- hoe, watering can, and seed hotbar flow
- tilling, watering, planting, overnight crop growth, harvesting
- shipping bin selling and money tracking
- bed-driven next-day flow
- save/load through \`user://savegame.json\`

## Controls

- \`WASD\` or arrow keys: move
- \`F\`: use selected tool or seeds
- \`E\` or \`Space\`: interact or harvest
- \`Tab\` or \`I\`: toggle inventory panel
- \`Q\` / \`R\`: cycle hotbar
- \`1-8\`: select hotbar slot
- \`F5\`: save game

## Project Layout

- \`scenes/main.tscn\`: main entry scene
- \`scenes/maps/\`: farm and house maps
- \`scenes/entities/player.tscn\`: player scene
- \`scripts/autoload/\`: global runtime services
- \`scripts/world/\`: tile palette, map base class, interactables
- \`scripts/logic/\`: pure logic helpers used by runtime and tests
- \`resources/\`: item, tool, and crop data resources
- \`tests/test_runner.gd\`: headless smoke-style regression tests

## Current Slice

The current implementation is intentionally thin but structured for expansion:

- data is resource-driven for items, tools, and crops
- cross-scene state lives in autoload services
- dynamic soil and crop state is stored by \`map_id + tile coordinate\`
- map scenes render static tiles plus dynamic soil/crop overlays
- the project uses runtime-generated placeholder tiles instead of final art

## Verification

The current baseline was verified with:

\`\`\`bash
godot --headless --path /home/yrd/projects/stardew-ai -s res://tests/test_runner.gd
godot --headless --path /home/yrd/projects/stardew-ai --quit
\`\`\`

## Next Steps

- add NPC schedules, dialogue, and one starter shop
- introduce quests and a simple social progression loop
- expand crop variety and farm economics
- formalize command/event boundaries for future multiplayer compatibility

