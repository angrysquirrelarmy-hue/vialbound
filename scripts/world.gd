## The test map, built in code so the spike has something to walk around in.
##
## This is scaffolding: the real world becomes an authored scene plus the
## prototype's generator. What matters here is that tiles, collision, ambient
## tint and lights all line up the way the render pipeline expects.
extends Node2D

const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const PATH := Vector2i(2, 0)
const TILLED := Vector2i(3, 0)
const PLANK := Vector2i(0, 1)
const WATER := Vector2i(1, 1)
const WALL := Vector2i(2, 1)
const ROCK := Vector2i(3, 1)

const MAP := Vector2i(48, 30)

@onready var ground: TileMapLayer = $Ground
@onready var lights: Node2D = $Lights
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	_lay_ground()
	_lay_hut(Vector2i(6, 5), Vector2i(9, 6))
	_lay_field(Vector2i(24, 8), Vector2i(14, 8))
	_lay_pond(Vector2i(34, 20), 5)
	_scatter_rocks(18)
	_hang_lanterns()
	for f: Node2D in get_tree().get_nodes_in_group(&"friend"):
		f.target = player

func _cell(c: Vector2i, atlas: Vector2i) -> void:
	ground.set_cell(c, 0, atlas)

func _lay_ground() -> void:
	for y in MAP.y:
		for x in MAP.x:
			var r := randf()
			_cell(Vector2i(x, y), GRASS_B if r < 0.22 else GRASS_A)
	for y in MAP.y:                                   # the path down the middle
		_cell(Vector2i(19 + int(sin(y * 0.3) * 1.5), y), PATH)
		_cell(Vector2i(20 + int(sin(y * 0.3) * 1.5), y), PATH)

func _lay_hut(at: Vector2i, size: Vector2i) -> void:
	for y in size.y:
		for x in size.x:
			var c := at + Vector2i(x, y)
			var edge := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			_cell(c, WALL if edge else PLANK)
	_cell(at + Vector2i(size.x / 2, size.y - 1), PLANK)     # doorway

func _lay_field(at: Vector2i, size: Vector2i) -> void:
	for y in range(0, size.y, 2):
		for x in size.x:
			_cell(at + Vector2i(x, y), TILLED)

func _lay_pond(at: Vector2i, r: int) -> void:
	for y in range(-r, r + 1):
		for x in range(-r - 2, r + 3):
			if (float(x) / (r + 2)) ** 2 + (float(y) / r) ** 2 <= 1.0:
				_cell(at + Vector2i(x, y), WATER)

func _scatter_rocks(n: int) -> void:
	for i in n:
		var c := Vector2i(randi_range(1, MAP.x - 2), randi_range(1, MAP.y - 2))
		if ground.get_cell_atlas_coords(c) == GRASS_A:
			_cell(c, ROCK)

func _hang_lanterns() -> void:
	for spot in [Vector2(11.5, 12.5), Vector2(31.5, 7.5), Vector2(25.5, 22.5), Vector2(21.5, 11.5), Vector2(18.5, 16.5)]:
		var l := PointLight2D.new()
		l.texture = preload("res://art/light_soft.png")
		l.texture_scale = 1.35
		l.color = Color(1.0, 0.72, 0.38)
		l.energy = 1.15
		l.position = spot * 16.0
		lights.add_child(l)
