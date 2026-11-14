# Rage Bounce

A Godot 4 bounce-focused platformer prototype.

## Features
- **Menu and end screens**: start from a main menu and finish with an end screen after completing all levels.
- **Level progression**: reach the `EXIT` portal to advance through levels (`level_0`–`level_4`).
- **Bounce-centric gameplay**: jump/bounce traversal with bounce pads and tunable bounce strength.
- **Lucky Blocks**: spend a reset anchor to gain a random benefit (restore controls or restore bounce) with visual reward feedback.
- **Hazards and resets**: fire hazards can defeat the player and trigger a level restart.

## Controls
- **Move**: `A` / `Left Arrow`, `D` / `Right Arrow`
- **Jump/Bounce**: `Space` / `Enter`
- **Restart level**: `R`
- **Switch levels (debug)**: `N` / `P`
- **Adjust bounce (after bounce reward/tuning enabled)**: `]` / `=` / Numpad `+` (increase), `[` / `-` / Numpad `-` (decrease)

## Project structure
- `project.godot` — Godot project configuration (main scene: menu)
- `scenes/` — game/UI scenes
  - `menu.tscn`, `end_screen.tscn` — menu and completion screens
  - `main.tscn` — gameplay scene (player, HUD, level container)
  - `player.tscn`, `fire.tscn`, `bounce_pad.tscn`, `lucky_block.tscn`, `level_exit.tscn`
  - `levels/` — level scenes (`level_0.tscn`–`level_4.tscn`)
- `scripts/` — GDScript gameplay/UI logic
- `assets/` — images, sounds, UI icons, and misc/raw assets

## Running
1. Open the folder in **Godot 4.x**.
2. Run the project (starts at `scenes/menu.tscn`).

## Notes
- Generated/editor cache files are ignored via `.gitignore` (e.g. `.godot/`).
- Some level layouts are currently variations of a shared base; they can be further redesigned for more distinct challenges.

