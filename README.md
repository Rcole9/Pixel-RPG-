# Runes of the Void

A **Godot 4.3.x** isometric pixel RPG blending WoW-style roles (Tank / Healer / DPS) with Destiny-style instanced dungeons, loot rarity, perks, and power-level progression.

---

## Requirements

| Requirement | Version |
|---|---|
| Godot | **4.3.x** (stable) |

---

## How to Run

1. Install **Godot 4.3.x** from https://godotengine.org/download
2. Clone this repository
3. Open Godot → **Import** → select the `project.godot` file in the repo root
4. Press **▶ Play** (F5)

> First launch goes straight to the class-select screen. No extra setup required.

---

## Controls

| Action | Key / Button |
|---|---|
| Move | **Left-click** (ground) |
| Attack enemy | **Left-click** on enemy |
| Interact (NPC) | **Left-click** on NPC within range |
| Pick up loot | **Right-click** on loot, or walk over it |
| Ability 1–3 | **1 / 2 / 3** |
| Ultimate | **4** |
| Open inventory | **I** |
| Save game | **F5** (or the Save button in HUD) |

---

## Gameplay Loop

```
Class Select → Overworld → Talk to Elder Aric (Quest) → Dungeon Entrance
                 ↓
           Dungeon (3 rooms of enemies) → Boss Room
                 ↓
           Boss: 2 Phases + telegraphed AoE + adds spawn
                 ↓
           Loot drops (rarity: Common → Legendary) → Equip in Inventory
                 ↓
           Return to Overworld / Save & Quit
```

---

## Classes

### 🛡 Tank
High HP · Mitigation · Aggro control
| Ability | Key | Effect |
|---|---|---|
| Shield Wall | 1 | +60% defense for 6 s |
| Taunt | 2 | Forces nearby enemies to target you (8 s) |
| Cleave | 3 | AoE melee 120° arc |
| Juggernaut | 4 | **Ultimate** – Barrier + damage reflect (10 s) |

### 💚 Healer
Medium HP · Sustain · Protective buffs
| Ability | Key | Effect |
|---|---|---|
| Mend | 1 | Instant heal 50 HP |
| Regenerate | 2 | HoT: 15 HP/s for 8 s |
| Holy Shield | 3 | Absorb next 80 damage |
| Resurrection Field | 4 | **Ultimate** – Heal 120 HP + cleanse all debuffs |

### ⚔ DPS
Low HP · Burst damage · Mobility
| Ability | Key | Effect |
|---|---|---|
| Power Strike | 1 | 2× damage single-target hit |
| Void Burst | 2 | AoE explosion 150 px radius |
| Shadow Step | 3 | Teleport 200 px toward cursor + Slow nearby |
| Death Mark | 4 | **Ultimate** – Target takes 2× damage for 8 s |

---

## Status Effects

| Effect | Description |
|---|---|
| **Burn** | 5 damage/s for 5 s |
| **Slow** | −50% move speed for 4 s |
| **Weaken** | −30% damage dealt for 6 s |
| **Regen** | Heal over time (from Healer Regenerate) |
| **Shield** | Absorb incoming damage (Holy Shield / Juggernaut) |

---

## Loot System

### Rarity Tiers

| Rarity | Drop Weight | Affixes | Perks |
|---|---|---|---|
| Common | 60% | 1 | — |
| Rare | 25% | 2 | — |
| Epic | 12% | 3 | 1 |
| Legendary | 3% | 4 | 2 |

### Equipment Slots
`weapon` · `helm` · `chest` · `boots` · `artifact`

### Perks (Legendary / Epic only)
- **Ignition** – 20% chance on attack to apply Burn
- **Glacial Touch** – 15% chance on attack to apply Slow
- **Vampiric** – Lifesteal 5% of damage dealt
- **Last Stand** – Below 30% HP gain an emergency shield
- **Rune Echo** – On kill: −10% remaining cooldowns
- **Void Hunger** – On kill: restore 10 resource

---

## Project Structure

```
Runes of the Void/
├── project.godot               ← Godot 4.3 project config
├── icon.svg
├── scenes/
│   ├── Main.tscn               ← Entry point (continue / new game)
│   ├── ClassSelect.tscn        ← Class selection screen
│   ├── Overworld.tscn          ← Open world zone + NPC + dungeon portal
│   ├── Dungeon.tscn            ← Instanced dungeon + boss
│   ├── entities/
│   │   ├── Player.tscn
│   │   ├── Enemy.tscn
│   │   ├── Boss.tscn
│   │   ├── NPC.tscn
│   │   └── LootDrop.tscn
│   └── ui/
│       └── HUD.tscn
└── scripts/
    ├── autoloads/
    │   ├── GameState.gd        ← Global player/quest/inventory state
    │   └── SaveLoad.gd         ← JSON save/load (user://savegame.json)
    ├── classes/
    │   ├── TankClass.gd
    │   ├── HealerClass.gd
    │   └── DPSClass.gd
    ├── entities/
    │   ├── Enemy.gd            ← AI: Idle → Patrol → Chase → Attack
    │   ├── Boss.gd             ← 2-phase boss + telegraphed AoE
    │   ├── NPC.gd              ← Quest giver
    │   └── LootDrop.gd
    ├── player/
    │   └── Player.gd           ← Click-to-move + ability system
    ├── scenes/
    │   ├── Main.gd
    │   ├── ClassSelect.gd
    │   ├── Overworld.gd
    │   └── Dungeon.gd
    ├── systems/
    │   └── LootSystem.gd       ← Item generation (rarity + affixes + perks)
    └── ui/
        └── HUD.gd              ← HP/resource bars, hotbar with cooldowns, loot notifications
```

---

## Save System

Saves are stored at `user://savegame.json` (location varies by OS):

| OS | Path |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Runes of the Void\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Runes of the Void/` |
| Linux | `~/.local/share/godot/app_userdata/Runes of the Void/` |

Saved data: player class, stats, inventory, equipped gear, quest progress, zone.

---

## License

TBD
