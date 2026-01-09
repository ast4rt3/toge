# Fast-Paced Roguelike (Godot 4)

This is a procedural 2D roguelike game template built in Godot 4.

## How to Play
1. Open the project in Godot 4.
2. Press **F5** to run the game.
3. **Controls**:
    - **WASD**: Move
    - **WASD**: Move (Free Look)
    - **Space**: Dash (Cooldown: 1s)
    - **Right Click (Hold)**: Aim Mode (Laser Sight, Slow Move)
    - **Left Click**: Fire (High Recoil, One-Shot Kill)
4. **Goal**: Survive!
    - **Safe Zone**: The starting room has a **green overlay**. Enemies **cannot enter** this area.
    - **Combat**: Leave the safe zone to fight.

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
