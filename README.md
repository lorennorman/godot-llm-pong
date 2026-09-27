# Pong

A simple local two-player game for Godot 4, with no external assets or dependencies.

Open `project.godot` in Godot and press **F6** with `main.tscn` open, or **F5** to run the project. From a terminal, run `./bin/play` (requires `godot` or `godot4` on your PATH). Additional arguments are passed to Godot.

- **Player 1:** W/A/S/D to move.
- **Player 2:** Arrow keys to move.
- **Space:** Pause or resume.
- **R:** Restart the match.
- **M:** Mute or unmute music.

The background music is an original eight-bar chiptune loop at 144 BPM, synthesized live with Godot's `AudioStreamGenerator`: pulse melody and arpeggios, triangle bass, and synthesized drums. No audio files are required.

Matching synthesized effects play at each serve, paddle impact, and match victory. Harder hits produce higher-pitched chirps. **M** mutes only the music; gameplay cues remain audible.

Each paddle stays within its own half. Hit with the paddle's edges to aim the ball; rallies gradually speed up. Score by getting the ball past the opposing side. First to **7** wins.

After each point, the conceding player's paddle movement speed, height, and bounce strength each increase by **10%**, stacking throughout the match. Bounce strength multiplies the outgoing ball speed, including the net proximity bonus, subject to the ball speed cap. Restarting restores both paddles to their initial stats.

Moving your paddle closer to the center net makes hits more powerful: each bounce adds a 6% speed boost plus up to 24% extra based on proximity to the net. Ball speed remains capped at 850 pixels per second.

## Web build and GitHub Pages

In the GitHub repository, open **Settings → Pages → Build and deployment** and set **Source** to **GitHub Actions**. Push to `main` (or run **Build and deploy web game** manually from the Actions tab) to build and deploy. The deployment's URL appears in the workflow run and the `github-pages` environment. No custom secrets are needed.

The workflow pins Godot **4.7.2**, verifies the official engine/template downloads against their SHA-512 checksums, and exports the `Web` preset to `build/web/index.html`. It uses a single-threaded build that works without custom server headers, and stream audio playback for the synthesizer. Click the game or press a key to enable audio if your browser blocks autoplay.

To build locally, install Godot 4.7.2 and its matching export templates, then run:

```bash
mkdir -p build/web
godot --headless --path . --editor --import
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open `http://localhost:8000` to play. Serve the exported files over HTTP rather than opening the HTML file directly.
