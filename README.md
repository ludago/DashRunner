# 🐤 Dash Runner

> An **endless runner** built with **Godot 4.4** — a bird on a journey that starts calm and ends in a storm.

![Godot](https://img.shields.io/badge/Godot-4.4-478CBF?logo=godotengine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Language](https://img.shields.io/badge/Language-GDScript-blue)
![Status](https://img.shields.io/badge/Status-Work%20in%20progress-orange)

---

## 🎮 About the Game

**Dash Runner** is a side-scrolling endless runner. Guide Dash, a small bird with a lot of road ahead, through **seven chapters** that each raise the stakes — a calm valley, a closing forest, a stone canyon, a burning desert, frozen mountains, a full storm, and finally the lighthouse.

The core loop is simple and readable at a glance: **jump, duck, and read the road ahead**. What changes is the road.

| Chapter | Name | Base speed | Introduces |
|:--:|---|:--:|---|
| 1 | El Valle Celeste | 400 | Jump |
| 2 | El Bosque de los Ecos | 430 | Ducking under flyers |
| 3 | El Cañón del Echo | 460 | Gaps, paired obstacles |
| 4 | El Desierto Ardiente | 500 | Falling predators |
| 5 | Las Montañas Heladas | 530 | Falling hazards, telegraphed |
| 6 | El Frente de la Tormenta | 570 | Everything, at once |
| 7 | El Faro de Vuelo | 550 | **A finish line** |

> **In development.** Chapter 1 is fully playable end to end. Chapters 2–7 are defined as data and playable, but their art and new obstacle types are still to be produced.

---

## ✨ Implemented

| Feature | Details |
|---|---|
| **Data-driven chapters** | Each chapter is a `.tres` resource. Speed, spawn rate, obstacle pool, weights, unlock scores and palette all come from data — adding a chapter is one new file, no code |
| **Chapter select** | 7 chapters with lock state and completion marks |
| **Narrative intros** | Per-chapter story screen, text loaded from the chapter resource |
| **4 obstacle types** | `ROCK_LOW` (jump), `ROCK_HIGH` (timed jump), `LOG_TUNNEL` (duck through a 30px gap), `BUSH` (wide jump) |
| **Progressive spawning** | Weighted random selection gated by score, so early game stays simple and later game escalates |
| **Hit feedback** | Camera shake → freeze frame (`Engine.time_scale` 0.05 for 180ms) → red flash → Game Over |
| **Scrolling ground detail** | Procedurally generated stones and grass that wrap seamlessly, so the ground actually moves with the speed |
| **HUD pulse** | Score label scales on every 100 points to make the counter feel alive |
| **Chapter title card** | Fades in from the resource on level start |
| **Graceful degradation** | Unimplemented obstacle types are declared in the enum and filtered by `is_implemented()`, so future chapters light up automatically as each obstacle ships |

---

## 🕹 Controls

| Action | Input |
|---|---|
| Jump | `Space` / `Enter` |
| Duck | `↓` |

Ducking halves Dash's height, which is what lets you pass the `LOG_TUNNEL` gap.

---

## 🛠 Technical Stack

- **Engine**: Godot 4.4.1
- **Language**: GDScript (typed, signal-driven)
- **Architecture**: Autoload singleton (`Global`) for cross-scene state + data-driven level resources
- **Rendering**: 5-layer `ParallaxBackground` with per-layer `motion_scale` (0.02 sky → 0.7 near hills) and `motion_mirroring` for seamless tiling
- **Collision**: `Area2D` per obstacle, `CharacterBody2D` player, manual gravity (project gravity is 0)
- **Testing**: headless integration tests runnable from the CLI

---

## 📁 Project Structure

```text
DashRunner/
├── assets/                   # Backgrounds (1152x648) + Dash sprite
│   ├── bg_sky.png
│   ├── bg_clouds.png
│   ├── bg_hills_{far,mid,near}.png
│   └── dash.png
├── resources/                # ⭐ Chapter definitions — one .tres per chapter
│   ├── level_data.gd         # LevelData resource (class_name)
│   └── level_01.tres … level_07.tres
├── scenes/
│   ├── Menu.tscn             # Title screen (Play / Continue)
│   ├── ChapterSelect.tscn    # Chapter grid with locks
│   ├── ChapterIntro.tscn     # Per-chapter story screen
│   ├── Game.tscn             # The single, generic gameplay scene
│   ├── GameOver.tscn
│   ├── Dash.tscn
│   └── Obstacle.tscn
├── scripts/
│   ├── Global.gd             # Autoload: score, records, chapter progress, level cache
│   ├── Game.gd               # Score, speed curve, camera FX, hit sequence
│   ├── Dash.gd               # Gravity, jump, duck, hit flash
│   ├── Obstacle.gd           # Obstacle types + per-type collision config
│   ├── ObstacleSpawner.gd    # Weighted spawning from LevelData
│   ├── ChapterSelect.gd
│   ├── ChapterIntro.gd
│   └── GameOver.gd
├── tests/                    # Headless integration tests
│   ├── test_niveles.{gd,tscn}       # All 7 .tres load + unlock logic
│   └── test_game_lectura.{gd,tscn}  # Game + spawner actually read LevelData
├── PLAN_FINISH_GAME.md       # Roadmap (phases 0-8) + pending-asset catalog
└── project.godot
```

---

## 🚀 Getting Started

### Prerequisites
- **Godot 4.4+** (standard build)

### Run locally

```bash
git clone https://github.com/ludago/dash-runner.git
cd dash-runner

# Open in Godot 4 and press F5 (or ▶ Play)
```

Or from the CLI:

```bash
godot --path . res://scenes/Menu.tscn
```

### Run the tests

The tests are scenes, so they need a real run (not `--check-only`, which doesn't register autoloads):

```bash
godot --headless --quit-after 300 res://tests/test_niveles.tscn
godot --headless --quit-after 300 res://tests/test_game_lectura.tscn
```

`test_niveles` prints every chapter's values and asserts the unlock progression.
`test_game_lectura` instantiates the gameplay scene per chapter and asserts the speed, palette, title and spawner rules came from the resource.

> **Note on the workflow:** add a chapter by copying a `.tres` in `resources/` and editing the numbers. `Game.gd`, `ObstacleSpawner.gd` and the scenes stay untouched. If it's the last chapter, bump `Global.MAX_CHAPTER`.

---

## 🗺 Roadmap

See [`PLAN_FINISH_GAME.md`](PLAN_FINISH_GAME.md) for the full breakdown (phases 0–8) plus a **catalog of every pending asset** with target sizes, collision specs and search keywords.

| Phase | Scope | Status |
|:--:|---|:--:|
| 0 | Data-driven chapters + chapter select | ✅ Complete |
| 1 | Polish Chapter 1 — impact feedback, scrolling ground, HUD | 🔶 In progress |
| 1 | Dash sprite animation, particles, obstacle variants, audio | ⬜ Pending |
| 2–6 | Chapters 2–6 and their new obstacle types | ⬜ Pending |
| 7 | Chapter 7 finish line + victory screen | ⬜ Pending |
| 8 | Free mode, disk persistence, credits, final polish | ⬜ Pending |

---

## 🎨 Art Direction

Flat **vector** illustration style, chosen to match the existing gradient backgrounds. Every obstacle is a placeholder `Polygon2D` today and will be swapped for a sprite — the collision shapes stay fixed and only the visual node is tuned, so hitboxes never drift from the art.

---

## 📜 License

MIT License — free to use, modify and distribute.

---

## 👨‍💻 Author

**ludago**
🎮 Building small games to learn the craft.
🔗 [GitHub](https://github.com/ludago)

---

> *Every expert was once a beginner. This is still level one — and it's fun.*
