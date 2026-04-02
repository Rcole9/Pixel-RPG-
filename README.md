# Runes of the Void

A Godot (4.3.x) isometric pixel RPG prototype blending WoW-style roles (Tank/Healer/DPS), questing zones, and dungeon/raid-lite encounters with Destiny-like instanced missions, loot rarity, perks, and power level progression.

> Status: bootstrap repo docs only. Gameplay prototype will be delivered via PR.

## Requirements
- Godot **4.3.x** (stable)

## How to run (once the prototype PR lands)
1. Install Godot 4.3.x.
2. Clone this repo.
3. Open the project in Godot.
4. Press **Play**.

## Controls (planned)
- **Left click:** move
- **Left click on enemy:** attack / interact
- **1–4:** abilities
- **I:** inventory
- **Esc:** menu

## Core gameplay loop (planned)
- Overworld zone → quest giver → dungeon entrance → instanced dungeon → boss → loot

## Design pillars
- **Roles matter:** tank mitigation + taunt-like aggro, healer sustain/buffs, dps burst/AoE.
- **Readable combat:** telegraphed attacks, status effects (burn/slow/weaken).
- **Loot chase:** rarity tiers (common/rare/epic/legendary), affixes + perks.
- **Progression:** power level influences damage dealt/taken.

## Roadmap
- [ ] Godot project scaffolding + pixel-perfect/isometric setup
- [ ] Player controller (click-to-move), combat, HUD
- [ ] 3 starter classes (Tank/Healer/DPS)
- [ ] Overworld + quest NPC
- [ ] Dungeon instance + boss with 2 phases
- [ ] Loot generator + inventory/equipment
- [ ] Save/load

## License
TBD