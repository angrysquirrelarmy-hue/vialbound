## You, and whatever you are currently wearing.
##
## One body, one sprite: taking a cryptid's shape swaps the sheet and the speed
## rather than spawning a different node, so the camera, collision and the light
## you carry never change hands.
extends CharacterBody2D

const HUMAN_SPEED := 58.0
const ACCEL := 900.0
const FRAME_TIME := 0.16

@export var human_sheet: Texture2D
@export var human_cell := Vector2i(16, 24)

@onready var sprite: Sprite2D = $Sprite
@onready var light: PointLight2D = $VialLight
@onready var shape: CollisionShape2D = $Shape

var facing := 0            # 0 down, 1 up, 2 left, 3 right
var walk_t := 0.0
var walk_frame := 0
var _pour := 0.0           # essence transition, 1 -> 0

func _ready() -> void:
	Game.form_changed.connect(_on_form_changed)
	_on_form_changed(null)

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var sp := Game.friend().speed if Game.friend() else HUMAN_SPEED
	velocity = velocity.move_toward(dir * sp, ACCEL * delta)
	move_and_slide()

	if dir.length() > 0.1:
		facing = (1 if dir.y < 0 else 0) if absf(dir.y) > absf(dir.x) else (2 if dir.x < 0 else 3)
		walk_t += delta
		if walk_t >= FRAME_TIME:
			walk_t = 0.0
			walk_frame = 1 + (walk_frame % 2)      # 1, 2, 1, 2 …
	else:
		walk_frame = 0
		walk_t = 0.0
	sprite.frame = facing * 3 + walk_frame
	sprite.flip_h = false

	if _pour > 0.0:
		_pour = maxf(0.0, _pour - delta * 3.0)
		sprite.scale = Vector2(1.0 - _pour * 0.55, 1.0 + _pour * 0.75)
		sprite.modulate = Color(1, 1, 1).lerp(Color(2.2, 2.0, 2.6), _pour)
		light.energy = lerpf(_base_energy, 2.6, _pour)
	elif sprite.scale != Vector2.ONE:
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
		light.energy = _base_energy

func _unhandled_input(_e: InputEvent) -> void:
	if Input.is_action_just_pressed(&"vial_1"):
		Game.wear(0)
	elif Input.is_action_just_pressed(&"vial_2"):
		Game.wear(1)
	elif Input.is_action_just_pressed(&"human_form"):
		Game.become_human()

var _base_energy := 0.55

func _on_form_changed(sp: Species) -> void:
	var cell := human_cell
	if sp:
		sprite.texture = sp.sheet
		cell = sp.cell
		light.color = sp.glow
		_base_energy = sp.glow_energy
	else:
		sprite.texture = human_sheet
		light.color = Color(0.72, 0.96, 0.95)
		_base_energy = 0.55
	sprite.hframes = 3
	sprite.vframes = 4
	# feet on the tile, whatever the cell height
	sprite.offset = Vector2(0, -float(cell.y) / 2.0 + 4.0)
	_pour = 1.0
