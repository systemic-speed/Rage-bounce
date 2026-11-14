# Rage Bounce

A small Godot 4 platformer project.

## Project structure

- `project.godot` — Godot project configuration
- `scenes/` — game scenes
  - `main.tscn` — main scene / entry composition
  - `player.tscn` — player scene
  - `fire.tscn` — fire/hazard scene
  - `levels/` — level scenes (e.g. `level_0.tscn`)
- `scripts/` — GDScript files (player, hazards, level/main logic)
- `assets/`
  - `imgs/` — sprites, tilesets, and other textures
  - `sounds/` — audio files and music
  - `misc/` — raw/extra art assets not currently used in scenes

## Running

1. Open the folder in **Godot 4.x**.
2. Run the project (main scene is configured in `project.godot`).

## Notes

- Generated/editor cache files are ignored via `.gitignore` (e.g. `.godot/`).
- Keep new scenes in `scenes/` and scripts in `scripts/` to maintain a consistent layout.

