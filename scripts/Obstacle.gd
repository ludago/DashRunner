extends Area2D
## Obstáculo que se mueve de derecha a izquierda y se autodestruye
## al salir de pantalla. Emite hit_dash cuando choca contra el jugador.
## Soporta múltiples tipos (ROCK_LOW, ROCK_HIGH, LOG_TUNNEL, BUSH) configurados vía setup().

signal hit_dash

## BIRD, PIT, CACTUS, VULTURE e ICE_FALL ya están declarados para que los
## .tres de los capítulos 2-7 los puedan listar, pero todavía no tienen arte
## ni comportamiento. IMPLEMENTED es la lista real de los que el juego sabe
## construir; ObstacleSpawner filtra por acá para no instanciar un tipo vacío.
enum Type { ROCK_LOW, ROCK_HIGH, LOG_TUNNEL, BUSH, BIRD, PIT, CACTUS, VULTURE, ICE_FALL }

const IMPLEMENTED: Array[int] = [
	Type.ROCK_LOW,
	Type.ROCK_HIGH,
	Type.LOG_TUNNEL,
	Type.BUSH,
]

static func is_implemented(type: int) -> bool:
	return IMPLEMENTED.has(type)

@export var obstacle_type: Type = Type.ROCK_LOW

var speed := 400.0

@onready var sprite: Polygon2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var collision_top: CollisionShape2D = $CollisionTop if has_node("CollisionTop") else null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_by_type()

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	if position.x < -200.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		hit_dash.emit()

func _configure_by_type() -> void:
	match obstacle_type:
		Type.ROCK_LOW:
			# Roca baja 30x50 - salto básico
			_apply_rect(30, 50, Color(0.8, 0.2, 0.2, 1), Vector2(0, -25), false)
		Type.ROCK_HIGH:
			# Roca alta 30x80 - salto con timing
			_apply_rect(30, 80, Color(0.9, 0.4, 0.1, 1), Vector2(0, -40), false)
		Type.LOG_TUNNEL:
			_setup_tunnel()
		Type.BUSH:
			# Arbusto 40x40 triángulo - salto ancho
			_apply_triangle(40, 40, Color(0.2, 0.7, 0.2, 1), Vector2(0, -20))
		_:
			# Tipo declarado pero todavía sin implementar. El spawner no debería
			# llegar acá; si llega, avisamos en vez de dejar un obstáculo mudo.
			push_warning("Tipo de obstáculo sin implementar: %d" % obstacle_type)

func _apply_rect(w: float, h: float, col: Color, col_pos: Vector2, _is_triangle: bool = false) -> void:
	# Polygon visual: rect centrado en 0,h/2 arriba del suelo (pies en 0)
	var hw := w / 2.0
	sprite.polygon = PackedVector2Array([Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw, 0), Vector2(-hw, 0)])
	sprite.color = col
	# Collision
	var shape := collision.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(w, h)
	collision.position = col_pos
	collision.disabled = false
	if collision_top:
		collision_top.disabled = true

func _apply_triangle(w: float, h: float, col: Color, col_pos: Vector2) -> void:
	var hw := w / 2.0
	# Triángulo con base en suelo
	sprite.polygon = PackedVector2Array([Vector2(-hw, 0), Vector2(hw, 0), Vector2(0, -h)])
	sprite.color = col
	var shape := collision.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(w, h)
	collision.position = col_pos
	collision.disabled = false
	if collision_top:
		collision_top.disabled = true

func _setup_tunnel() -> void:
	# Tronco hueco 50x60 con hueco central 30px alto donde Dash agachado (30px) pasa
	# Visual: marco en U - representamos con rect con hueco visual (dos rects simulados con polygon de marco)
	var w := 50.0
	var h := 60.0
	var wall := 15.0
	var gap := 30.0
	# Polygon de marco: forma de rect con ventana. Usamos 8 puntos para hueco
	# Puntos: borde exterior + borde interior (agujero)
	sprite.polygon = PackedVector2Array([
		Vector2(-w/2, -h), Vector2(w/2, -h), Vector2(w/2, 0), Vector2(-w/2, 0),
	])
	sprite.color = Color(0.55, 0.35, 0.15, 1)
	# Para diferenciar visual, dibujamos marco: usaremos color marrón y dejamos hueco transparente
	# Como Polygon2D no soporta hueco, simulamos con dos rects visuales: usaremos el polygon principal
	# y el hueco se nota por colisiones separadas. Pintamos hueco con overlay más oscuro si quisiera,
	# pero por ahora color sólido.
	# Colisiones: dos barras arriba y abajo del hueco
	var bottom_h := (h - gap) / 2.0 # 15
	var top_h := (h - gap) / 2.0    # 15
	# Bottom collision (desde suelo hacia arriba 15px)
	var shape_bot := collision.shape as RectangleShape2D
	if shape_bot:
		shape_bot.size = Vector2(w, bottom_h)
	collision.position = Vector2(0, -bottom_h/2.0) # -7.5
	collision.disabled = false
	# Top collision (barra superior)
	if collision_top:
		var shape_top := collision_top.shape as RectangleShape2D
		if shape_top:
			shape_top.size = Vector2(w, top_h)
		collision_top.position = Vector2(0, -h + top_h/2.0) # -52.5
		collision_top.disabled = false
	# Marcar hueco visual: achicar polygon y dejar espacio - para placeholder lo dejamos rect sólido
	# pero la colisión ya deja paso.
