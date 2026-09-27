extends CharacterBody2D
## Controla al personaje Dash: gravedad, salto y agachado.
## Controles: Espacio / Enter para saltar, flecha Abajo para agacharse.

const GRAVITY := 2200.0
const JUMP_VELOCITY := -850.0
const DUCK_SCALE := Vector2(1.0, 0.5)

# Duración del parpadeo rojo al chocar.
const FLASH_HIT_FADE := 0.3

var is_ducking := false

@onready var sprite: Sprite2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

var _base_sprite_scale: Vector2
var _base_sprite_pos: Vector2
var _base_collision_pos: Vector2
var _base_collision_scale: Vector2

func _ready() -> void:
	_base_sprite_scale = sprite.scale
	_base_sprite_pos = sprite.position
	_base_collision_pos = collision.position
	_base_collision_scale = collision.scale

func _physics_process(delta: float) -> void:
	# Gravedad manual (el proyecto tiene la gravedad global en 0)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Agacharse (solo en el suelo)
	if Input.is_action_pressed("ui_down") and is_on_floor():
		_set_duck(true)
	else:
		_set_duck(false)

	move_and_slide()


func _set_duck(state: bool) -> void:
	if state == is_ducking:
		return
	is_ducking = state
	if is_ducking:
		# Achica a la mitad en Y manteniendo el pie en el suelo:
		# escala relativa a la base (0.28 -> 0.14) y posición Y a la mitad (-50 -> -25)
		sprite.scale = _base_sprite_scale * DUCK_SCALE
		sprite.position = Vector2(_base_sprite_pos.x, _base_sprite_pos.y * DUCK_SCALE.y)
		collision.scale = _base_collision_scale * DUCK_SCALE
		collision.position = Vector2(_base_collision_pos.x, _base_collision_pos.y * DUCK_SCALE.y)
	else:
		sprite.scale = _base_sprite_scale
		sprite.position = _base_sprite_pos
		collision.scale = _base_collision_scale
		collision.position = _base_collision_pos

## Parpadeo rojo al recibir un impacto. Ignora time_scale para que el
## destello se vea completo durante el freeze frame del golpe.
func flash_hit() -> void:
	modulate = Color(1.0, 0.25, 0.25)
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(self, "modulate", Color.WHITE, FLASH_HIT_FADE)
