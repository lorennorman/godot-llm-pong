# Pong

A simple local two-player game for Godot 4, with no external assets or dependencies.

Open `project.godot` in Godot and press **F6** with `main.tscn` open, or **F5** to run the project. From a terminal, run `./bin/play` (requires `godot` or `godot4` on your PATH). Additional arguments are passed to Godot.

- **Player 1:** W/A/S/D to move.
- **Player 2:** Arrow keys to move.
- **Space:** Pause or resume.
- **R:** Restart the match.

Each paddle stays within its own half. Hit with the paddle's edges to aim the ball; rallies gradually speed up. Score by getting the ball past the opposing side. First to **7** wins.
