# The Living World

A developing 3D school and life simulation inspired by Greater Giyani, Limpopo, South Africa.

## Current status

**Early development. This is not a finished game.** The current Godot scene is a small playable foundation with block-based placeholder buildings, a student, a robot, simple NPC movement, a clock, and Director Mode controls. It does not yet include realistic school assets, complete story mode, real CAPS lessons, API-key management, local AI, saves, or a validated Windows installer.

## Current Godot source

- `project.godot` — Godot 4 project settings.
- `scenes/main.tscn` — entry scene.
- `scripts/main.gd` — procedural school scene, student and robot controls, simple NPCs, camera, time and Director Mode.
- `export_presets.cfg` — Windows export preset.
- `.github/workflows/windows.yml` — workflow intended to export a Windows executable.

## Legacy Python source

- `main.py` — original Panda3D prototype, retained for reference.
- `requirements.txt` — Panda3D dependency.

## Run from source

1. Install Godot 4.4 (standard, non-.NET editor).
2. Clone or download this repository.
3. Open the folder in Godot and import `project.godot`.
4. Press F6 on `scenes/main.tscn` or F5 to run the main project.

Controls: WASD to move, Shift to run, F1 for Director Mode, Tab to switch student/robot while in Director Mode, 1/2/3 for time speed, P to pause NPC movement, N to change sky, Esc to exit.

## Windows build

See the repository Actions tab for the `Windows Game Export` workflow. Its successful completion and EXE output have **not been verified**. An EXE is not the same as an installer; an installer requires an additional packaging step.

## Development direction

The intended full game includes detailed fictionalized regional environments, authentic curriculum-aligned lessons, autonomous characters, persistent saves, a robot storyline, Director Sandbox, optional Gemini and local AI integration, and a Windows installer. These are planned features, **not implemented claims**.

Do not commit actual API keys, private location information, or unlicensed third-party assets.
