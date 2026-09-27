# Dash Runner — Plan de Finalización (Cap. 1 → 7 → Cierre)

Documento de trabajo. Cada fase se marca con `[ ]` (pendiente) → `[x]` (hecho).
**Regla:** un capítulo no se marca como terminado hasta cumplir su criterio de "Terminado".

---

## 📍 Cómo usar este doc

1. Abrís el doc, elegís la fase más urgente.
2. Hacés el trabajo, marcás las casillas.
3. Cuando fulfilles el criterio de "Terminado", pasás a la siguiente fase.
4. Actualizá también `GAME_DESIGN.md` si cambia algo del diseño original.

> 🔎 **Buscás un sprite o un sonido?** Todo está catalogado en el **[Apéndice A](#-apéndice-a--catálogo-de-assets-pendientes)** al final del documento, con tamaños, colores, colisión que debe coincidir y keywords de búsqueda.

---

## 🔍 Estado actual del proyecto (a día de hoy)

### Ya funciona
| Elemento | Archivo |
|---|---|
| Menú principal con "Jugar" y "Continuar" | `scenes/Menu.tscn` + `scripts/Menu.gd` |
| Selección de capítulo con 7 botones y bloqueos | `scenes/ChapterSelect.tscn` + `scripts/ChapterSelect.gd` |
| Pantalla de capítulo (texto narrativo desde el `.tres`) | `scenes/ChapterIntro.tscn` + `scripts/ChapterIntro.gd` |
| Nivel jugable con parallax 5 capas | `scenes/Game.tscn` + `scripts/Game.gd` |
| Personaje con salto + agachado | `scenes/Dash.tscn` + `scripts/Dash.gd` |
| 4 tipos de obstáculo con progresión por score | `scenes/Obstacle.tscn` + `scripts/Obstacle.gd` |
| Spawner con tabla de pesos y desbloqueo por score | `scripts/ObstacleSpawner.gd` |
| Game Over con puntaje / récord | `scenes/GameOver.tscn` + `scripts/GameOver.gd` |
| Autoload de datos entre escenas + progreso de capítulos | `scripts/Global.gd` |
| **7 capítulos definidos como datos** (velocidad, spawn, obstáculos, colores) | `resources/level_01.tres` … `level_07.tres` + `resources/level_data.gd` |

### Cómo agregar un capítulo nuevo ahora
1. Copiar un `.tres` de `resources/` y cambiar los valores.
2. Agregarlo a `Global.MAX_CHAPTER` si es el último.
No hace falta tocar `Game.gd`, `ObstacleSpawner.gd` ni ninguna escena.

### Tipos de obstáculo que ya existen
| Enum | Forma | Se esquiva con | Dónde aparece |
|---|---|---|---|
| `ROCK_LOW` | Rect 30×50 rojo | Salto | cap. 1+ |
| `ROCK_HIGH` | Rect 30×80 naranja | Salto (timing) | cap. 1+ |
| `LOG_TUNNEL` | Marco 50×60 con hueco 30px | **Agacharse** | cap. 1+ |
| `BUSH` | Triángulo 40×40 verde | Salto ancho | cap. 1+ |
| `BIRD` `PIT` `CACTUS` `VULTURE` `ICE_FALL` | declarados, sin implementar | — | cap. 2-7 (se filtran solos) |

### Lo que NO existe todavía
- ❌ Sonido (ni música ni SFX)
- ❌ Animaciones de Dash / obstáculos (todo es `Polygon2D` + `Sprite2D` estático)
- ❌ Partículas (sí existe el screen shake y el flash de impacto)
- ❌ Arte de fondo de los capítulos 2-7 (por eso muestran color plano de cielo)
- ❌ Pantalla de victoria
- ❌ Persistencia en disco (el récord y los capítulos desbloqueados se pierden al cerrar)
- ❌ Marcar un capítulo como superado al jugarlo (el `mark_chapter_cleared()` existe pero nadie lo llama todavía: se conecta en Fase 7 con la victoria)

---

## 🧱 FASE 0 — Base común (hacer PRIMERO, desbloquea todo)

> Sin esto, cada capítulo nuevo es una copia manual de `Game.tscn`. Con esto, cada capítulo es **un archivo de datos**.

### 0.1 Resource `LevelData`
- [x] Crear `resources/level_data.gd` con `@export`:
  - `chapter_number: int`
  - `chapter_title: String` (ej. `"El Valle Celeste"`)
  - `narrative: String` (texto de la intro)
  - `speed_base: float` (400 en cap. 1, 430 en cap. 2, …)
  - `speed_increase_rate: float`
  - `spawn_min: float` / `spawn_max: float` (intervalo aleatorio)
  - `background_color: Color` (cielo de respaldo)
  - `obstacle_types: Array[int]` (tipos permitidos en este capítulo)
  - `is_story_chapter: bool` (cap. 7 = tramo con final, no infinito)
  - `target_score: int` (para cap. 7 = longitud del tramo)
  - `class_name LevelData` para que se use tipado en el resto de los scripts
  - **Extras que hicieron falta** (no estaban en el plan original): `ground_color`, `uses_background_art`, `obstacle_weights: Array[int]`, `obstacle_min_scores: Array[int]`. Los tres arrays de obstáculos van alineados por índice; si faltan pesos o mínimos, el spawner usa 1 y 0.
- [x] Crear `resources/level_01.tres` … `level_07.tres` con los valores del GDD

### 0.2 Registro de capítulos en el autoload
- [x] En `scripts/Global.gd` agregar:
  - `unlocked_chapter: int = 1`
  - `chapter_cleared: Dictionary = {}` (cap → true/false)
  - `current_chapter: int = 1`
  - `load_level_data(chapter: int) -> LevelData` (cachea el `.tres`)
  - `set_current_chapter(chapter)` / `get_current_level_data()` para que Menu, ChapterSelect, ChapterIntro y Game lean el mismo
  - `is_chapter_unlocked()`, `is_chapter_cleared()`, `chapter_title()`
  - `mark_chapter_cleared(chapter)` que abre el siguiente, con tope en `MAX_CHAPTER`

### 0.3 `Game.gd` lee de `LevelData`
- [x] Reemplazar los `var speed := 400.0` / `speed_increase_rate` hardcodeados por valores de `LevelData`
- [x] `ObstacleSpawner` recibe `obstacle_types` permitidos desde `LevelData` en vez de la tabla por score
- [x] `ChapterIntro` muestra `chapter_title` + `narrative` leyendo del `.tres`
- [x] `Game.gd` aplica `background_color` (cielo de respaldo) y `ground_color` (suelo) desde el `.tres`
- [x] `uses_background_art = false` oculta el parallax del cap. 1 en los capítulos que todavía no tienen arte, así no se ven las colinas del valle en el desierto
- [x] Los tipos de obstáculo **no implementados** (BIRD, PIT, CACTUS, VULTURE, ICE_FALL) ya están declarados en el enum y los `.tres` de los cap. 2-7 los listan, pero `ObstacleSpawner` los filtra con `Obstacle.is_implemented()` hasta que existan. Cada tipo se activa solo al hacer su fase
- [x] Título del capítulo en el HUD desde el `.tres`, con fade out a los 3 s (esto también resuelve el primer ítem de 1.5)

### 0.4 Menú de capítulos
- [x] Nueva escena `scenes/ChapterSelect.tscn` con `GridContainer` de 7 botones
- [x] Botón bloqueado si `cap > Global.unlocked_chapter` (muestra "Bloqueado")
- [x] `Menu.tscn`: botón "Jugar" → `ChapterSelect.tscn`; botón "Continuar" → último capítulo desbloqueado
- [x] `ChapterSelect` → `ChapterIntro` → `Game`

**Terminado Fase 0 cuando:** puedo desbloquear Cap. 2, entrar, jugar un nivel con sus reglas, y el HUD/title salen del `.tres` sin tocar código.

> ✅ **Cumplido.** Verificado con `tests/test_niveles.tscn` y `tests/test_game_lectura.tscn`.
> El cap. 1 quedó con exactamente los mismos valores que antes (vel 400, inc 8, pesos 100/30/20/15, mínimos 0/500/1000/1500), así que no hubo regresión.
> Para re-verificar:
> ```
> Godot_v4.4.1-stable_win64.exe --path <proyecto> --headless --quit-after 300 res://tests/test_niveles.tscn
> Godot_v4.4.1-stable_win64.exe --path <proyecto> --headless --quit-after 300 res://tests/test_game_lectura.tscn
> ```
> **Ojo al probar:** `godot --headless --check-only --script res://scripts/Game.gd` va a decir `Identifier not found: Global` aunque el código esté bien, porque en ese modo no se registran los autoloads. Para validar, correr la escena: `--headless --quit-after 90 res://scenes/Game.tscn`.


---

## 🌅 FASE 1 — Terminar el Capítulo 1 (El Valle Celeste)

> El GDD lo marca como "tutorial". Hoy es funcional pero se siente como un rectángulo rojo sobre colinas. El objetivo es que se sienta **jugable y con alma**, sin meteringle todavía laTormenta.

### 1.1 Feedback de impacto (lo más notorio)
- [x] **Screen shake**: `Camera2D` en `Game.tscn` → sacudida aleatoria de 6 pasos (9px, 45ms) en `Game.gd`
- [x] **Freeze frame**: `Engine.time_scale = 0.05` por 0.18s al chocar, luego restaurado a 1.0
- [x] **Flash**: `Dash.flash_hit()` → parpadeo rojo (0.3s) con tween que ignora `time_scale`
- [x] **Secuencia encadenada**: freeze → restore → 0.25s → `GameOver.tscn` (`_play_hit_sequence()`)
- [x] **Sacudida de puntaje**: el `ScoreLabel` escala 1.25 → 1.0 cada 100 puntos
- [x] **Suelo desplazable**: piedras y pastos generados por código (`_build_ground_detail()`) que se mueven a velocidad completa y envuelven cada 200px. El suelo base era un rect estático de 2000px y no había ninguna referencia de movimiento a los pies de Dash — por eso el nivel se veía parado aunque el fondo sí se desplazara.

### 1.2 Animaciones de Dash
- [ ] `dash.png` es una sola imagen → crear `assets/sprites/dash_sheet.png` (o 4 PNGs: `dash_idle`, `dash_run`, `dash_jump`, `dash_duck`)
- [ ] Cambiar `Sprite2D` por `AnimatedSprite2D` en `Dash.tscn`
- [ ] Crear `assets/anim/dash_idle.tres`, `dash_run.tres`, `dash_jump.tres`, `dash_duck.tres` (`SpriteFrames`)
- [ ] En `Dash.gd`: máquina de estados `idle → run → jump → fall → duck` según `is_on_floor()` / `velocity.y` / `is_ducking`
 - [ ] Animación de correr a 8-12 fps (estilo pixel art), salto en 2 frames

### 1.3 Partículas
- [ ] `assets/fx/dust.png` (círculo blanco suave, 32×32)
- [ ] `GPUParticles2D` "Dust" hijo de `Dash` — emite al correr (suelo) y al aterrizar (ráfaga)
- [ ] Partículas de "puesta" al esquivar un obstáculo cerca
- [ ] `CPUParticles2D` en `Obstacle` — polvo al "romper" un arbusto

### 1.4 Obstáculos con variación
- [ ] Dejar `ROCK_LOW` como el "placeholder rojo" y agregar 2 variantes visuales nuevas:
  - `assets/obstacles/rock_a.png`, `rock_b.png` (o `Polygon2D` con paletas distintas)
- [ ] `Obstacle.gd`: `@export var visual_variant: int` → el spawner lo aleatoriza
- [ ] Implementar el hueco visual del `LOG_TUNNEL` (hoy es un rect sólido que se ve mal): usar un `Polygon2D` con `polygons` múltiples (Polygon2D soporta huecos con `build_mode = ` y varios `polygon`/`uv`)
- [ ] Quitar el `CollisionTop` deshabilitado del `.tscn` si `LOG_TUNNEL` ya se resuelve con polígonos

### 1.5 HUD de Capítulo 1
- [x] Mostrar el título del capítulo en la esquina superior izquierda durante los primeros 3 segundos (fade out) — sale del `LevelData` (se hizo en Fase 0.3)
- [ ] Indicador visual sutil de la velocidad actual (una barra o el puntaje que cambia de color)
- [ ] Feedback al desbloquear un tipo nuevo: texto "¡Cuidado con los obstáculos altos!" la primera vez que aparece `ROCK_HIGH`

### 1.6 Sonido (Cap. 1)
- [ ] `assets/audio/jump.wav` — salto corto
- [ ] `assets/audio/land.wav` — aterrizaje sordo
- [ ] `assets/audio/hit.wav` — choque
- [ ] `assets/audio/point.wav` — tic por cada 100 puntos (o cada 1000)
- [ ] `assets/audio/music_valle.ogg` — loop 60-90s, tranquilo, campanas de viento
- [ ] Crear `scripts/AudioManager.gd` como autoload: `play_sfx(name)`, `play_music(name)`, `stop_music()`
- [ ] `Bus` de audio: `SFX` (vol 0.7) / `Music` (vol 0.4)

**Terminado Fase 1 cuando:** el nivel se siente "vivo" (animado, con sonido, con impacto al chocar) y un jugador nuevo entiende los controles sin leer nada.

---

## 🌲 FASE 2 — Capítulo 2: El Bosque de los Ecos

**Texto:** *"Los árboles se cierran sobre el camino. Algo revolotea entre las ramas: los primeros pájaros asustados por el viento que se acerca."*

- [ ] `level_02.tres`: `speed_base = 430`, cielo más oscuro, `obstacle_types` = `[ROCK_LOW, BIRD]`
- [ ] **Decisión de diseño:** el GDD dice que el agacharse se introduce con los pájaros, pero `LOG_TUNNEL` ya lo usa. Elegí:
  - **Opción A (recomendada):** `LOG_TUNNEL` se usa en Cap. 1-2 como "tronco bajo", y el **pájaro** (`BIRD`) es el obstáculo nuevo que obliga a agacharse a media altura
  - **Opción B:** `LOG_TUNNEL` queda para el Cap. 3, y el Cap. 2 arranca solo con pájaros
- [ ] Nuevo tipo `BIRD`: Sprite2D 40×20 volando a `y = -40` respecto al suelo, colisión como arco o rect bajo
- [ ] Animación de aleteo (2-3 frames)
- [ ] Fondo nuevo: `bg_bosque_far.png`, `bg_bosque_mid.png`, `bg_bosque_near.png` (troncos verticales, luz más tenue)
- [ ] Cielo con menos brillo: `bg_sky_bosque.png` o modular el color del cielo
- [ ] Música: `music_bosque.ogg` — más弦 tensa, viento entre hojas
- [ ] Alternancia de obstáculos: forzar patrón "roca → pájaro" cada 2-3 spawns
- [ ] Pop-up de narración al iniciar: "Se escuchan alas entre los árboles."

**Terminado:** el jugador tiene que **leer** cada obstáculo (bajo vs. volador) y no reaccionar siempre igual.

---

## 🏜️ FASE 3 — Capítulo 3: El Cañón del Eco

**Texto:** *"El camino se estrecha entre paredes de piedra. El eco del viento suena cada vez más parecido a un trueno."*

- [ ] `level_03.tres`: `speed_base = 460`, cielo gris, tipos = `[ROCK_LOW, BIRD, PIT]`
- [ ] Nuevo tipo `PIT`: hueco en el suelo. Requiere:
  - [ ] Convertir el suelo (`Ground` de `Game.tscn`) en un `TileMapLayer` o en varios `StaticBody2D`分段 para poder abrir huecos
  - [ ] Ou usar `PIT` como "tramo sin suelo": un `Area2D` de daño + hueco visual con `Polygon2D` recortado
  - [ ] **Decisión de diseño:** el suelo continuo es la base del runner. Alternativa más simple: `PIT` es un `Obstacle` con `PIT` visual (una grieta oscura) que se salta — no un hueco real
- [ ] **Paredes de cañón**: 2 `ParallaxLayer` verticales (izq/der) con `motion_scale.x` bajo, texturas oscuras
- [ ] **Patrones en pares**: sistema de oleadas en `ObstacleSpawner` (nuevo `wave_patterns: Array[Array[int]]`)
  - [ ] Patrón "doble": 2 `ROCK_LOW` pegadas
  - [ ] Patrón "escalonado": `ROCK_LOW` + `ROCK_LOW` delay 0.35s
  - [ ] Patrón "mixto": `BIRD` + `PIT`
- [ ] Eco: `AudioStreamPlayer` con reverberación al chocar contra pared (o al pasar cerca)
- [ ] Música: `music_canon.ogg` — percusión lenta, Spannung
- [ ] Pop-up: "El eco ya suena a trueno."

**Terminado:** aparecen 2 obstáculos seguidos con spacing que obliga a planear el timing, no solo reaccionar.

---

## 🏜️ FASE 4 — Capítulo 4: El Desierto Ardiente

**Texto:** *"El sol pega fuerte, pero el calor no es nada comparado con la nube negra que ya se ve en el horizonte."*

- [ ] `level_04.tres`: `speed_base = 500`, cielo naranja, tipos = `[ROCK_LOW, BUSH, CACTUS, VULTURE]`
- [ ] Nuevo tipo `CACTUS`: 25×60 verde con espinas (bajo, se salta)
- [ ] Nuevo tipo `VULTURE`: buitre en picada, **cae desde arriba** en un patrón vertical — obligar a anticipar
  - [ ] Comportamiento nuevo en `Obstacle.gd`: `movement_pattern` (`NONE`, `FALL`, `SINE`)
  - [ ] `FALL`: empieza arriba fuera de cámara, cae a velocidad Y
- [ ] Fondo: `bg_desert_sky.png` (naranja), `bg_desert_dune_far/mid/near.png` (dunas)
- [ ] Calor: `CPUParticles2D` de ondas de calor en la capa baja, o shader de distorsión simple
- [ ] Música: `music_desierto.ogg` — percusión seca, ritmo más rápido
- [ ] Música/ambiente: primeraappearance de la tormenta lejana (sonido grave crescendo)
- [ ] Pop-up: "Una nube negra aparece en el horizonte."

**Terminado:** la velocidad se siente notable y hay un obstáculo (`VULTURE`) que no se esquiva saltando.

---

## ❄️ FASE 5 — Capítulo 5: Las Montañas Heladas

**Texto:** *"El aire se enfría de golpe. La tormenta está tan cerca que ya nieva."*

- [ ] `level_05.tres`: `speed_base = 530`, paleta fría, tipos = `[ROCK_LOW, CACTUS, ICE_FALL]`
- [ ] Nuevo tipo `ICE_FALL`: bloque de hielo que cae del cielo en zona puntual
  - [ ] Previsualización: sombra en el suelo 0.4s antes de caer (`tween` de modulate/alpha)
  - [ ] Colisión durante la caída, desaparece al impactar (con `particles` de hielo roto)
- [ ] Fondo: `bg_mountains_sky.png` (celeste pálido), `bg_mountain_far/mid/near.png` (picos nevados)
- [ ] Nieve decorativa: `CPUParticles2D` en `CanvasLayer` con `ParticleProcessMaterial` de copos, independiente de la capa de juego
- [ ] Sonido: viento helado, hielo crujiendo al pisar
- [ ] Música: `music_hielo.ogg` — cuerdas, más lenta pero tensa
- [ ] Pop-up: "Nieva. La tormenta está muy cerca."

**Terminado:** hay 2 tipos de obstáculo que exigen **anticipar** (prever dónde caen), no solo reaccionar a tiempo.

---

## 🌪️ FASE 6 — Capítulo 6: El Frente de la Tormenta

**Texto:** *"La tormenta alcanzó a Dash. Rayos, viento y lluvia: el tramo más duro de toda la carrera."*

- [ ] `level_06.tres`: `speed_base = 570`, `speed_increase_rate` alta, cielo oscuro, tipos = `[todos los anteriores]`
- [ ] Efecto de lluvia: `GPUParticles2D` en `CanvasLayer` (lluvia rápida, diagonal)
- [ ] Relámpagos: `Timer` aleatorio → `ColorRect` blanco en `CanvasLayer` con `tween` de 2-3 flashes rápidos
  - [ ] Opcional: shake leve de cámara durante el rayo
- [ ] Viento visual: `ParallaxLayer` de lluvia horizontal desplazándose rápido
- [ ] Reduced `spawn_min` (0.6s) → menos descanso entre obstáculos
- [ ] Música: `music_tormenta.ogg` — la más intensa, todo instrumental activo
- [ ] Pop-up: "¡La tormenta llegó!"
- [ ] Considerar: difficulties — si el jugador muere mucho, ofrecer "reintentar sin checkpoint" o bajar ligeramente la velocidad inicial de este capítulo

**Terminado:** es el nivel más difícil, visualmente claramente distinto, y todos los tipos de obstáculo se mezclan.

---

## 🗼 FASE 7 — Capítulo 7: El Faro de Vuelo (final)

**Texto:** *"Dash llega al Faro justo a tiempo y enciende la señal. Toda la bandada alza vuelo detrás de ella, justo antes de que la tormenta cubra el valle."*

> **Este capítulo NO es un runner infinito.** Es un **tramo corto con final definido** que termina en pantalla de victoria.

- [ ] `level_07.tres`: `is_story_chapter = true`, `target_score = 6000` (o distancia), `speed_base = 550` (rápido pero no imposible)
- [ ] Objetivo visual: **la torre del Faro** visible en el horizonte, acercándose con el scroll
- [ ] Al alcanzar el objetivo:
  - [ ] Cambiar a **escena de victoria** (`scenes/Victory.tscn`): fireworks/partículas, bandada de Dash volando, texto "¡La señal está encendida!"
  - [ ] En vez de `change_scene_to_file(GameOver)`, ir a `Victory`
- [ ] Música: `music_faro.ogg` — espere, momento de Macht, cuerdas crecientes
- [ ] `Victory.tscn` con:
  - [ ] Texto de victoria + puntaje final + tiempo
  - [ ] Botón "Volver al menú" / "Jugar el runner libre"
- [ ] `Global.chapter_cleared[7] = true` al completar

**Terminado:** se puede **ganar** el juego con una pantalla de victoria clara.

---

## 🎊 FASE 8 — Cierre del juego

### 8.1 Modo libre (post-juego)
- [ ] Después de Ganar el Cap. 7, `Menu` desbloquea "Modo Libre": runner infinito con Cap. 1-6 obstáculos mezclados, sin objetivo, para competir por puntaje
- [ ] Es la escena `Game.tscn` con un `LevelData` "libre" (velocidad máxima, todos los tipos)

### 8.2 Persistencia real
- [ ] `Global.gd` → guardar con `ConfigFile` en `user://dashrunner.cfg`:
  - `high_score`
  - `unlocked_chapter`
  - `chapter_cleared`
  - `last_score` (opcional)
- [ ] Cargar en `_ready()` del autoload
- [ ] Detrás de los servicios: pantalla de **récords por capítulo** (mejor score de cada uno)

### 8.3 Créditos
- [ ] `scenes/Credits.tscn` con el texto de la historia completa (resumen de los 7 capítulos), controles, créditos de assets
- [ ] Enlazada desde `Menu` y `Victory`

### 8.4 Pulido final
- [ ] Pausa (`Esc` / `P`) con menú de pausa (reanudar / reiniciar / menú)
- [ ] Opciones: volumen de música / SFX, pantalla completa
- [ ] Tutorial real en Cap. 1: primeras 2-3 spawns son solo `ROCK_LOW` muy espaciados + texto flotante ("Espacio = saltar", "Flecha abajo = agacharse")
- [ ] Feedback háptico (vibración) en móvil si se exporta a Android
- [ ] Revisión de rendimiento: object pooling para obstáculos (hoy se instancian/destruyen sin parar)
- [ ] Nombre del juego y icono definitivos (reemplazar `icon.svg` placeholder)

---

## 🔧 Deuda técnica a resolver en algún momento

- [x] ~~`ObstacleSpawner.gd` usa `"score" in game` (línea 43) — frágil~~ → **resuelto en Fase 0**: ahora lee `Global.get_current_level_data()` y usa `current_level_data` del Game
- [ ] **Object pooling** de obstáculos — hoy se hace `instantiate()`/`queue_free()` constante
- [ ] `Obstacle.gd` tiene lógica de `LOG_TUNNEL` muy comentada y confusa (líneas 72-106) — limpiar cuando se implemente el hueco real
- [ ] `Game.gd` y `ObstacleSpawner.gd` dependen de que `Global.current_chapter` esté bien puesto. Si se entra a `Game.tscn` directo (F5 en el editor) arranca en el capítulo 1
- [ ] `verify-setup.ps1` en el starter-kit tiene un bug: usa `$Host` (variable reservada en PowerShell) en `Test-Port` — arreglar para que funcione el chequeo
- [ ] `setup.ps1` del starter-kit tiene error de sintaxis PowerShell (escaping de regex) — nunca corrió completo
- [ ] `export_presets.cfg`: cambiar `CAMBIA_ESTA_PASSWORD` por el keystore real antes de exportar a Android
- [ ] `.vscode/settings.json` y `.gitignore` están OK, pero el `.gitignore` ignora `.vscode/` — si querés versionar la config, sacalo de ahí

---

## 📌 Resumen visual del progreso

| Fase | Qué es | Estado |
|---|---|---|
| 0 | Base común (LevelData + menú de capítulos) | `[x]` **COMPLETA** |
| 1 | Terminar Cap. 1 (anim, sonido, feedback) | `[ ]` — parcial (1.1 ✅, 1.5 parcial ✅) |
| 2 | Cap. 2 — El Bosque de los Ecos | `[ ]` |
| 3 | Cap. 3 — El Cañón del Eco | `[ ]` |
| 4 | Cap. 4 — El Desierto Ardiente | `[ ]` |
| 5 | Cap. 5 — Las Montañas Heladas | `[ ]` |
| 6 | Cap. 6 — El Frente de la Tormenta | `[ ]` |
| 7 | Cap. 7 — El Faro de Vuelo (victoria) | `[ ]` |
| 8 | Cierre (modo libre, persistencia, créditos) | `[ ]` |

---

**Última actualización:** [fecha]

---
---

# 📎 APÉNDICE A — Catálogo de assets pendientes

Referencia para el **pase de assets**. Todo lo de acá es placeholder hoy y se reemplaza en los pases de arte.

## 🔑 Regla de oro del pase de assets

> **El tamaño del sprite NO se toca la colisión.**
> `Obstacle.tscn` y `Dash.tscn` definen las `CollisionShape2D`. Al cambiar un `Polygon2D` por un `Sprite2D`/`AnimatedSprite2D`, el hitbox queda igual. Solo hay que ajustar la `position` y `scale` del nodo visual para que el sprite *se vea* 만큼 alineado con el hitbox.
>
> Verificá siempre con la colisión a la vista: Godot → `Debug` → `Visible Collision Shapes`.

**Convención de nombres y rutas**

| Tipo | Ruta | Formato |
|---|---|---|
| Fondos | `assets/bg/<capitulo>/bg_<capa>.png` | PNG 1152×648, tileable en X |
| Obstáculos | `assets/obstacles/<nombre>.png` | PNG con transparencia |
| Personaje | `assets/sprites/dash_<estado>.png` | PNG con transparencia |
| FX | `assets/fx/<efecto>.png` | PNG 32–128 px |
| UI | `assets/ui/<elemento>.png` | PNG |
| Audio | `assets/audio/sfx_<efecto>.wav` · `assets/audio/music_<capitulo>.ogg` | WAV / OGG |

**Estilo objetivo:** pixel art o vector flat coherente con los fondos actuales (que son degradados suaves, no pixel art). **Decidir antes de producir** — mixingar estilos se nota mucho.

---

## 🐤 1. Personaje — Dash

Estado actual: `dash.png` único, 342×357 px, renderizado a `scale 0.28` (~96×100 en pantalla). Hitbox 40×60. El PNG tiene mucho padding transparente.

**Necesario:** sprite sheet o PNGs separados por estado. La animación de correr es lo que más impacta en la sensación de velocidad.

| Estado | Frames | FPS | Notas |
|---|---|---|---|
| `dash_idle` | 2–4 | 6 | Respiración leve, en el sitio |
| `dash_run` | 4–6 | 10–12 | **El más importante.** Patas alternas, cuerpo levemente inclinado adelante |
| `dash_jump` (subida) | 2 | 8 | Patas recogidas |
| `dash_fall` (caída) | 2 | 8 | Patas extendidas hacia adelante |
| `dash_duck` | 1–2 | — | Agachado, **debe medir ~30 px de alto** (el hueco del tronco) |
| `dash_hit` | 1 | — | Pose de impacto, se usa 1 frame en el flash |

**Specs:** el sprite completo (con padding) se dibuja centrado, con los pies en el origen. Alto en pantalla del `dash_run` ≈ 60 px (igual al hitbox).

**Keywords de búsqueda:** `runner character sprite sheet` · `pixel art bird running` · `character run cycle 4 frames` · `dinosaur runner sprite`

**En el código:** `scenes/Dash.tscn` — reemplazar `Sprite2D` por `AnimatedSprite2D` + `SpriteFrames`; máquina de estados en `scripts/Dash.gd`.

---

## 🪨 2. Obstáculos

Sizes de colisión tomados de `scripts/Obstacle.gd` — el sprite debe coincidir con ellos.

| Enum | Placeholder actual | Colisión | Se esquiva con | Cap. | Keywords |
|---|---|---|---|---|---|
| `ROCK_LOW` | rect rojo | **30×50**, base en el suelo | Salto | 1 | `low rock sprite` · `stone obstacle` |
| `ROCK_HIGH` | rect naranja | **30×80**, base en el suelo | Salto (timing) | 1 | `tall rock sprite` |
| `LOG_TUNNEL` | rect marrón **sólido** | **50×60**, hueco central de **30 px** | **Agacharse** | 1 | `hollow log sprite` · `tree trunk tunnel` |
| `BUSH` | triángulo verde | **40×40** triángulo | Salto ancho | 1 | `bush sprite` · `foliage obstacle` |
| `BIRD` | ❌ no existe | **40×20**, vuela a media altura | **Agacharse** | 2 | `flying bird sprite` · `bird obstacle side scroller` |
| `PIT` | ❌ no existe | grieta en el suelo | Salto (preciso) | 3 | `ground crack sprite` · `pit hole platformer` |
| `CACTUS` | ❌ no existe | **25×60**, base en el suelo | Salto | 4 | `cactus sprite` · `desert obstacle` |
| `VULTURE` | ❌ no existe | buitre en picada, cae de arriba | anticipar + agacharse | 4 | `vulture sprite` · `bird of prey diving` |
| `ICE_FALL` | ❌ no existe | bloque de hielo que cae | anticipar | 5 | `falling ice block sprite` · `icicle hazard` |

### Detalle importante — `LOG_TUNNEL`
Hoy el **visual es un rectángulo marrón macizo** pero la **colisión ya tiene el hueco correcto** (dos barras separadas: 15 px abajo + 15 px arriba, gap de 30 px). Al poner el sprite hay que respetar ese hueco: el PNG debe tener **transparencia en los 30 px centrales**, y el `dash_duck` tiene que medir ≤30 px de alto para pasar.

### Variación (Fase 1.4)
Para que no se vea repetido, cada tipo de obstáculo debería tener **2–3 variantes visuales** de la misma silueta/tamaño (misma hitbox, distinto detalle). El spawner las elige al azar. Ej: `rock_a.png`, `rock_b.png`, `rock_c.png` — todas 30×50.

### Animación
Los obstáculos no necesitan animación obligatoria, pero **sí** una entrada/salida suave si el estilo es pixel art (un frame de "polvo" al aparecer). Los que más lo necesitan: `BIRD` (aleteo de 2–3 frames) e `ICE_FALL` (rotación al caer).

---

## 🏞️ 3. Fondos — 5 capas × 7 capítulos

Formato **obligatorio**: 1152×648 px, tileable en X sin costura (las capas con `motion_mirroring = Vector2(1152, 0)` se repiten cada 1152 px).

### Capas y velocidad de parallax

| Capa | `motion_scale` | Qué va dibujado | Se mueve |
|---|---|---|---|
| `bg_sky` | 0.02 | cielo / degradado / sol / luna | casi nada |
| `bg_clouds` | 0.12 | nubes / estrellas / auroras | lento |
| `bg_<x>_far` | 0.25 | montañas /_colinas_ lejanas | medio |
| `bg_<x>_mid` | 0.45 | siluetas medias | medio-rápido |
| `bg_<x>_near` | 0.70 | terreno más cercano, Bossoles | rápido |

### Paleta por capítulo

| Cap. | Nombre | Cielo | Notas de ambiente | Assets a crear |
|---|---|---|---|---|
| 1 | El Valle Celeste | celeste `#87CFF0` *(actual)* | colinas verdes, sol | ☐ ya existen los 5 |
| 2 | El Bosque de los Ecos | verde apagado, poca luz | troncos verticales densos, luz entre ramas | ☐ 5 capas nuevas |
| 3 | El Cañón del Eco | gris `#8A8A8A` | paredes verticales oscuras a los lados | ☐ 5 capas + 2 paredes laterales |
| 4 | El Desierto Ardiente | naranja `#E8944A` | dunas, sol fuerte, calor | ☐ 5 capas |
| 5 | Las Montañas Heladas | celeste pálido `#B8D4E8` | picos nevados, cielo vacío | ☐ 5 capas |
| 6 | El Frente de la Tormenta | gris oscuro `#2A2E35` | nubes negras, sin sol | ☐ 5 capas |
| 7 | El Faro de Vuelo | amanecer dorado | amanecer saliendo **+ la torre del Faro** | ☐ 5 capas + `faro_torre.png` |

**Keywords de búsqueda:** `seamless parallax background 1152x648` · `parallax forest/desert/canyon layers` · `pixel art parallax background pack`

---

## 🧱 4. Suelo y detalle

| Asset | Estado actual | Qué hace |
|---|---|---|
| `GroundVisual` (base marrón) | `Polygon2D` 2000×40 | franja estática del terreno — **puede quedarse como está** |
| Detalle de suelo | generado por código (11 piedras/pastos) | se desplaza a velocidad completa y envuelve |
| Tile de terreno | ❌ no existe | textura repetible para el suelo, en vez de color plano |

Si querés suelo con textura, buscá `seamless dirt/grass/sand tile 64x64` y repetilo — pero ojo: el actual `Polygon2D` es **estático** y el detalle se mueve, así que el tile también tiene que ir en el nodo `GroundScroll`.

| Asset | Para qué |
|---|---|
| `tile_grass.png` | Cap. 1–2, 3 (bordes) |
| `tile_dirt.png` | Cap. 3 |
| `tile_sand.png` | Cap. 4 |
| `tile_snow.png` | Cap. 5 |
| `tile_stone.png` | Cap. 6 |
| `detail_stone.png`, `detail_grass.png` | las marcas que hoy se generan por código |

---

## ✨ 5. FX y partículas

| Asset | Para qué | Notas |
|---|---|---|
| `dust.png` | polvo al correr / aterrizar | círculo blanco suave, 32×32, con degradado radial |
| `spark.png` | impacto / choque | 16×16, para el frame de flash |
| `ice_shard.png` | `ICE_FALL` al romperse | 24×24 |
| `leaf.png` | Cap. 2, hojas volando | 16×16 |
| `raindrop.png` | Cap. 6, lluvia | línea de 4×32 |
| `snowflake.png` | Cap. 5, nieve | 12×12 |
| `feather.png` | Cap. 2/4, aftermath de `BIRD`/`VULTURE` | 16×16 |
| `firework.png` | Cap. 7, pantalla de victoria | 64×64 |

---

## 🎨 6. UI

| Asset | Estado actual | Nota |
|---|---|---|
| `icon.png` | `icon.svg` placeholder | el export preset apunta a `res://icon.png`, hay que crearlo |
| Fondo del menú | `ColorRect` celeste | reemplazar por imagen con el valle |
| Fondo de Game Over | `ColorRect` oscuro | idem |
| Pantalla de victoria | ❌ no existe | para el Cap. 7 |
| Marco de HUD | ❌ no existe | opcional, para el `ScoreLabel` |
| Botones | estilo por defecto de Godot | conviene un `StyleBoxFlat` con la paleta del juego |
| Fuente | por defecto de Godot | Considerar una pixel font (`Press Start 2P` y similares) |

---

## 🔊 7. Audio

### SFX (cortos, se usan en varios capítulos)

| Archivo | Cuándo | Duración |
|---|---|---|
| `sfx_jump.wav` | salto | ~0.15s |
| `sfx_land.wav` | aterrizaje | ~0.1s |
| `sfx_hit.wav` | choque | ~0.4s |
| `sfx_score.wav` | cada 100 puntos | ~0.08s (tic) |
| `sfx_duck.wav` | agacharse | ~0.1s |
| `sfx_spawn.wav` |egen obstáculo | ~0.15s |
| `sfx_ice.wav` | hielo rompiéndose | ~0.5s |
| `sfx_thunder.wav` | relámpago Cap. 6 | ~1.5s |
| `sfx_firework.wav` | victoria | ~1s |

### Música (1 loop por capítulo, 60–90 s)

| Archivo | Cap. | Estilo |
|---|---|---|
| `music_valle.ogg` | 1 | tranquilo, campanas de viento |
| `music_bosque.ogg` | 2 | más tenso, viento entre hojas |
| `music_canon.ogg` | 3 | percusión lenta, eco |
| `music_desierto.ogg` | 4 | percusión seca, más rápido |
| `music_hielo.ogg` | 5 | cuerdas frías, contenidas |
| `music_tormenta.ogg` | 6 | el más intenso, todo activo |
| `music_faro.ogg` | 7 |Resolver, cuerdas crecientes |
| `music_menu.ogg` | — | loop del menú |
| `music_victory.ogg` | — | jingle corto de victoria |

**Buses de audio:** `SFX` (vol 0.7) · `Music` (vol 0.4). Ver Fase 1.6.

**Fuentes de audio libre:** [Kenney.nl](https://kenney.nl/assets) (todo CC0, ideal para esto) · [freesound.org](https://freesound.org) · [opengameart.org](https://opengameart.org)

---

## ✅ Checklist de integración por asset

Para cada asset nuevo, mismos pasos:

- [ ] 1. El archivo está en `assets/<carpeta>/` con el nombre de la convención
- [ ] 2. La escena tiene el nodo visual (`Sprite2D` / `AnimatedSprite2D`) con la textura
- [ ] 3. `position` y `scale` del nodo visual alineados con la `CollisionShape2D`
- [ ] 4. Probado con las colisiones a la vista (`Debug` → `Visible Collision Shapes`)
- [ ] 5. Si es sprite de obstáculo, las variantes se agregaron a la tabla del spawner
- [ ] 6. Probado a velocidad máxima del capítulo (que no se vea "flotando" ni "clavado")
- [ ] 7. Marcado `[x]` en la fase correspondiente de este documento

---

## 📊 Resumen de cantidad de assets

| Categoría | Cantidad estimada |
|---|---|
| Dash (estados) | 6 |
| Obstáculos base | 5 (4 existentes + variantes) |
| Obstáculos nuevos (Cap. 2–5) | 5 |
| Fondos (5 capas × 7 cap.) | 35 |
| Suelo / tiles | 6 |
| FX / partículas | 8 |
| UI | 7 |
| SFX | 9 |
| Música | 9 |
| **Total** | **~90 archivos** |

