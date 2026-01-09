# Fast-Paced Roguelike (Godot 4)

This is a procedural 2D roguelike game template built in Godot 4.

## How to Play
1. Open the project in Godot 4.
2. Press **F5** to run the game.
3. **Controls**:
    - **WASD**: Move
    - **WASD**: Move (Free Look)
    - **Space**: Dash (Cooldown: 1s)
    - **Q**: Switch Weapon (Sniper <-> Katana)
    - **Right Click (Hold)**: Aim Mode (Rotate towards mouse, move slower)
    - **Left Click**: Attack (Shoot or Slash)
4. **Goal**: Survive!
    - **HP**: You have **5 HP**. Taking damage grants temporary invulnerability.
    - **Death**: Reaching 0 HP triggers a Game Over screen.
    - **Weapons**:
        - **Sniper**: Long range, requires aiming. High recoil.
        - **Katana**: Close range, wide slash. Steps forward on attack (Lunge).
    - **Enemies**: Beware the **Zombies**! They chase you relentlessly.
    - **Safe Zone**: The starting room has a **green overlay**. Zombies **cannot enter** this area.
    - **Combat**: Leave the safe zone to fight.
    - **Debug**: Press **F1** to toggle debug visuals.
        - **Debug Mode**: Shows Placeholders (Blocks/Icons) for clarity.
        - **Debug Mode**: Shows Placeholders (Blocks/Icons) for clarity.
        - **Normal Mode**: Shows Assets (Cave Tileset).
        - **Customizing Walls**: Open `scenes/WallFront.tscn` (and Top/Left/Right) to change the look of each wall side individually.
        - **Random Variation**: If you select a Texture Region larger than 32x32 (e.g. 96x32), the game will randomly pick one 32x32 tile from that area for each instance!

## Project Structure
- `scenes/Level.tscn`: Main scene. Contains the procedural generator.
- `scenes/level_generator.gd`: Generates **Rooms and Corridors**.
    - **Safe Zone**: The first room is filled with **Barriers** (Layer 4) that block enemies but not players.
    - **Enemy Zones**: Deep rooms contain enemies.
- `scenes/Player.tscn`: The player character with Dash ability.
- `scenes/Enemy.tscn`: Basic enemy that tracks the player.
- `scenes/Floor.tscn` & `scenes/Wall.tscn`: Level building blocks.

## Customization
- **Level Size**: Edit `scenes/Level.tscn` -> `Level` node -> `Max Tiles` / `Enemy Count`.
- **Player Speed**: Edit `scenes/Player.tscn` -> `Player` node -> `Speed` / `Dash Speed`.
