## A friend walking with you, out of its vial and not being worn.
##
## It trails rather than mirrors: it only closes the gap when you get far enough
## ahead, which is what stops a pack from looking like a rigid formation.
extends Node2D

@export var species: Species
@export var follow_distance := 22.0
@export var speed := 52.0

@onready var sprite: Sprite2D = $Sprite

var target: Node2D
var facing := 0
var walk_t := 0.0
var walk_frame := 0

func _ready() -> void:
	if species:
		sprite.texture = species.sheet
		sprite.hframes = 3
		sprite.vframes = 4
		sprite.offset = Vector2(0, -float(species.cell.y) / 2.0 + 4.0)
	Game.form_changed.connect(_on_form_changed)
	_on_form_changed(Game.friend())

func _process(delta: float) -> void:
	if target == null:
		return
	var to := target.global_position - global_position
	if to.length() > follow_distance:
		var step := to.normalized() * speed * delta
		global_position += step
		facing = (1 if to.y < 0 else 0) if absf(to.y) > absf(to.x) else (2 if to.x < 0 else 3)
		walk_t += delta
		if walk_t >= 0.16:
			walk_t = 0.0
			walk_frame = 1 + (walk_frame % 2)
	else:
		walk_frame = 0
	sprite.frame = facing * 3 + walk_frame

func _on_form_changed(sp: Species) -> void:
	# worn friends are inside the vial, so they are not also standing next to you
	visible = species == null or sp == null or sp.id != species.id
