# Stardew AI Agent Guide

Read `README.md` and `ARCHITECTURE.md` before making architectural changes.

## Repo Rules

- Keep long-lived gameplay state and orchestration in `scripts/autoload/`.
- Keep calculations, migrations, and other side-effect-light helpers in `scripts/logic/`.
- Keep schemas in `scripts/data/` and concrete content in `resources/`.
- Keep map scripts, interactables, player scripts, and UI scripts thin. They should mostly handle input, rendering, projection, and routing into services.
- Prefer extending existing services over pushing more gameplay flow into `scripts/entities/player.gd`.
- Prefer direct Godot signals between known services. Do not add a global event bus unless the current signal graph becomes unmanageable.
- Avoid deep node traversal like `get_parent().get_parent().get_node(...)`. Use injected references, scene setup, or signals instead.
- Keep gameplay results consistent with the current service contract when possible: `success`, `message`, `time_cost`, `events`, and optional `directives`.
- Update docs when runtime boundaries or gameplay claims change.

## Placement Guide

- Long-lived runtime state and gameplay orchestration: `scripts/autoload/`
- Pure or near-pure rules and save migration helpers: `scripts/logic/`
- Resource schemas: `scripts/data/`
- Content instances: `resources/`
- Shared world rendering and interactables: `scripts/world/`
- Concrete map behavior: `scripts/maps/`
- Entity input/projection: `scripts/entities/`
- HUD and modal UI: `scripts/ui/`

## Verification

```bash
godot --headless --path /home/yrd/projects/stardew-ai -s res://tests/test_runner.gd
godot --headless --path /home/yrd/projects/stardew-ai --quit
```
