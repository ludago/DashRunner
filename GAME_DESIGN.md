# Dash Runner — Documento de Diseño (GDD)

Runner 2D estilo "Chrome Dino" protagonizado por Dash, la mascota de Flutter.
Motor: **Godot 4.3+** (GDScript).

## 1. Concepto

Dash corre automáticamente de izquierda a derecha por un escenario infinito.
El jugador solo controla el salto y el agachado para esquivar obstáculos que
aparecen desde el borde derecho de la pantalla. La velocidad del juego
aumenta con el tiempo, y el objetivo es sobrevivir el mayor tiempo posible
para conseguir el puntaje más alto.

## 2. Controles

| Acción      | Tecla                  |
|-------------|------------------------|
| Saltar      | Espacio / Enter (`ui_accept`) |
| Agacharse   | Flecha Abajo (`ui_down`)      |

## 3. Bucle de juego (Game Loop)

1. El jugador presiona "Jugar" en el menú.
2. Dash corre automáticamente; el puntaje sube con el tiempo.
3. Obstáculos aparecen a intervalos aleatorios y se mueven hacia Dash.
4. El jugador salta o se agacha para esquivarlos.
5. La velocidad global aumenta progresivamente (dificultad creciente).
6. Al chocar con un obstáculo → pantalla de Game Over con puntaje y récord.
7. El jugador puede reintentar o volver al menú.

## 4. Mecánicas principales

- **Movimiento automático**: Dash no se mueve en X; el mundo se mueve hacia
  él (obstáculos con velocidad negativa en X). Esto simplifica el "scroll
  infinito" sin necesitar reposicionar fondos.
- **Salto**: velocidad vertical instantánea negativa (`JUMP_VELOCITY`),
  gravedad manual aplicada en `_physics_process`. Solo se puede saltar
  estando en el suelo (`is_on_floor()`).
- **Agachado**: escala el sprite y la colisión de Dash a la mitad de altura
  mientras se mantiene presionada la flecha abajo, para esquivar obstáculos
  "altos" (como pájaros voladores en niveles futuros).
- **Dificultad progresiva**: `speed` aumenta con cada frame
  (`speed_increase_rate`), y cada obstáculo nuevo hereda la velocidad actual
  del juego al instanciarse.
- **Puntaje**: sube con el tiempo sobrevivido (10 puntos/segundo). El
  puntaje final y el récord se guardan en un autoload (`Global.gd`) para
  pasar de la escena de juego a la de Game Over.
- **Colisiones**: los obstáculos son `Area2D` que detectan a Dash
  (`CharacterBody2D` en el grupo `"player"`) mediante `body_entered`, y
  emiten una señal `hit_dash` que el `Game.gd` escucha para terminar la
  partida.
- **Fondo en parallax**: 5 capas (`bg_sky`, `bg_clouds`, `bg_hills_far`,
  `bg_hills_mid`, `bg_hills_near`) dentro de un `ParallaxBackground`, cada
  una con un `motion_scale` distinto (0.02 → 0.7). `Game.gd` mueve
  `background.scroll_offset.x` según `speed`, así las capas lejanas se
  desplazan mucho menos que las cercanas, dando sensación de profundidad
  respecto al suelo y los obstáculos (que sí se mueven a velocidad completa).
  Las colinas están generadas con funciones periódicas para que se puedan
  repetir horizontalmente sin costuras (`motion_mirroring`).

## 5. Estructura de escenas

```
Menu.tscn      → Pantalla de inicio (Jugar)
Game.tscn      → Nivel jugable (Dash + suelo + spawner + UI de puntaje)
Dash.tscn      → Personaje reutilizable (instanciado dentro de Game.tscn)
Obstacle.tscn  → Obstáculo reutilizable (instanciado por el spawner)
GameOver.tscn  → Pantalla final (puntaje, récord, reintentar / menú)
```

Script autoload `Global.gd` → guarda `last_score` y `high_score` entre
escenas (no se puede pasar por variables locales al usar
`change_scene_to_file`).

## 6. Historia (modo historia / hilo narrativo)

**Título: "Dash y la Carrera del Amanecer"**

Contexto: en el Valle Celeste vive una bandada de aves-nube. Cada año,
antes de que llegue la Gran Tormenta de invierno, la bandada migra hacia
El Faro de Vuelo, un punto de encuentro en la cima de las montañas desde
donde parten todas juntas hacia el sur. Este año la tormenta se adelantó:
va a llegar mucho antes de lo previsto. Dash, la corredora más veloz de la
bandada, se ofrece a adelantarse sola, cruzar todas las regiones del valle
y llegar al Faro a tiempo para encender la señal que avisa a el resto de
la bandada por dónde volar y cuándo partir. Cada nivel es una región del
recorrido de Dash, cada vez más cerca de la tormenta y más difícil de
cruzar. Esta narrativa le da un motivo a la dificultad creciente: no es
solo "más rápido porque sí", es la tormenta que le pisa los talones.

El hilo de cada capítulo se puede mostrar como un cartel/pantalla breve
antes de arrancar el nivel (1–2 líneas de texto, en la pantalla de Menú o
en una pantalla intermedia "Capítulo X"), y funciona como diseño de nivel:
define paleta de fondo, tipo de obstáculo nuevo y qué mecánica se
introduce.

### Capítulo 1 — El Valle Celeste *(incluido en este proyecto — Nivel 1)*
> "Todo empieza con un cielo tranquilo. Dash se despide de su nido y
> arranca la carrera contra el tiempo."

- Fondo: colinas verdes, cielo despejado, sol (ya generado).
- Obstáculo: rocas/troncos bajos (bloque rojo actual).
- Mecánica: introduce salto y agachado. Velocidad base 400 px/s.
- Rol narrativo: tutorial — el valle todavía no muestra señales de la
  tormenta que se viene.

### Capítulo 2 — El Bosque de los Ecos
> "Los árboles se cierran sobre el camino. Algo revolotea entre las ramas:
> los primeros pájaros asustados por el viento que se acerca."

- Fondo: bosque más denso, luz más tenue entre los árboles.
- Obstáculo nuevo: pájaros a media altura → obligan a **agacharse** en vez
  de saltar (ya estaba planeado en el roadmap).
- Mecánica: alterna obstáculos bajos (saltar) y altos (agacharse) para
  que el jugador tenga que leer cada obstáculo, no reaccionar siempre igual.
- Velocidad base un poco mayor (ej. 430 px/s).

### Capítulo 3 — El Cañón del Eco
> "El camino se estrecha entre paredes de piedra. El eco del viento suena
> cada vez más parecido a un trueno."

- Fondo: paredes de cañón en los laterales (capas de parallax más altas
  y oscuras), cielo más gris.
- Obstáculo nuevo: huecos/pozos en el suelo que exigen saltos más
  precisos (timing), combinados con las rocas y pájaros anteriores.
- Mecánica: obstáculos empiezan a aparecer en pares/patrones cortos, no
  solo uno por uno.

### Capítulo 4 — El Desierto Ardiente
> "El sol pega fuerte, pero el calor no es nada comparado con la nube
> negra que ya se ve en el horizonte."

- Fondo: paleta cálida (arena, cactus, cielo anaranjado).
- Obstáculo nuevo: cactus (bajos, saltar) y buitres en picada (altos,
  agacharse), más frecuentes que antes.
- Mecánica: aumenta la velocidad base considerablemente; primer nivel
  donde el jugador siente que "ya no puede relajarse".

### Capítulo 5 — Las Montañas Heladas
> "El aire se enfría de golpe. La tormenta está tan cerca que ya nieva."

- Fondo: paleta fría (blancos, grises, celestes), copos de nieve cayendo
  como decoración.
- Obstáculo nuevo: rocas de hielo que caen desde arriba en zonas puntuales
  (obligan a anticipar, no solo reaccionar) + los obstáculos de niveles
  previos combinados.
- Mecánica opcional: el suelo "resbaladizo" podría reducir levemente el
  control (idea para más adelante, no obligatoria).

### Capítulo 6 — El Frente de la Tormenta
> "La tormenta alcanzó a Dash. Rayos, viento y lluvia: el tramo más duro
> de toda la carrera."

- Fondo: oscuro, con relámpagos ocasionales (destellos rápidos de luz de
  fondo) y lluvia.
- Obstáculo: todos los tipos anteriores mezclados, apareciendo más rápido
  y con menos espacio entre patrones. Es el nivel más difícil.
- Mecánica: aquí es donde el "modo historia" se pone más cerca del modo
  score infinito actual (máxima dificultad sostenida).

### Capítulo 7 — El Faro de Vuelo (final)
> "Dash llega al Faro justo a tiempo y enciende la señal. Toda la bandada
> alza vuelo detrás de ella, justo antes de que la tormenta cubra el
> valle."

- Fondo: amanecer/tormenta quedando atrás, colores volviendo a la calma
  (transición visual de tormenta a amanecer dorado).
- Puede jugarse como un tramo corto y espectacular (en vez de "hasta que
  pierdas") que termina en una pantalla de victoria en lugar de Game Over,
  cerrando la historia. Después de este capítulo, el juego puede seguir en
  "modo libre" (el runner infinito que ya existe) para seguir compitiendo
  por puntaje.

Esta estructura de 7 capítulos entra dentro de lo pedido (menos de 10) y
cada uno ya tiene: paleta de fondo, obstáculo nuevo y motivo narrativo, así
que se puede ir armando de a un nivel por vez usando el Nivel 1 actual como
plantilla (copiar `Game.tscn`, cambiar texturas de fondo/obstáculos y los
parámetros de `speed` / `speed_increase_rate`).

## 7. Nivel 1 (incluido en este proyecto)

- Fondo celeste liso, suelo marrón continuo.
- Un único tipo de obstáculo (bloque rojo) que aparece cada 1.0–2.2 s
  (intervalo aleatorio).
- Velocidad inicial: 400 px/s, aumenta ~8 px/s².
- Objetivo del nivel: introducir salto/agachado y la curva de dificultad
  base. Sirve como plantilla para los siguientes niveles.
- En términos de la historia: es el Capítulo 1, "El Valle Celeste".

## 8. Roadmap de próximos niveles / mejoras

Ideas para iterar una vez que el Nivel 1 esté probado (ver también los
Capítulos 2 a 7 de la sección de Historia, que ya definen tema/obstáculo
por nivel):

- **Nivel 2 (Cap. 2 — Bosque)**: introducir el pájaro volador a media
  altura que obliga a agacharse en vez de saltar.
- **Nivel 3 (Cap. 3 — Cañón)**: paredes de cañón en parallax + huecos en
  el suelo que exigen saltos más precisos.
- **Power-ups**: monedas para sumar puntos extra, escudo temporal, doble
  salto.
- **Arte real**: reemplazar los `Polygon2D`/sprites placeholder por
  animaciones (idle, run, jump) usando `AnimatedSprite2D`.
- **Sonido**: efectos de salto, choque y música de fondo con
  `AudioStreamPlayer` (distinta por capítulo, para reforzar el ambiente).
- **Persistencia real**: guardar el récord en disco con `FileAccess` /
  `ConfigFile` en vez de solo en memoria (`Global.gd`).
- **Dificultad por patrones**: en vez de solo aumentar velocidad, definir
  secuencias de obstáculos (patrones) que se vuelven más complejas por
  capítulo.
- **Pantalla de "Capítulo X"**: una escena corta tipo cartel entre niveles
  que muestre el texto narrativo de cada capítulo antes de arrancarlo.

## 9. Nota sobre el personaje

Dash es la mascota oficial del proyecto Flutter (Google). Para uso personal
o educativo no hay problema en inspirarse en su diseño; si el juego se
publicara comercialmente conviene revisar antes las pautas de marca de
Google/Flutter.
