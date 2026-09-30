## One cryptid kind. Everything that differs between friends lives here, so adding
## a species is a new .tres in data/species/ rather than a new branch in code.
class_name Species
extends Resource

## Short id used in save data and slot lookups.
@export var id: StringName = &""
@export var display_name: String = ""
## What this friend is FOR: pick, dig, claws, bow, magic, grow, swim, ride.
@export var calling: StringName = &"claws"
@export var sheet: Texture2D
## Cell size in the sheet. Wide friends get a wider cell than the 16x24 human.
@export var cell: Vector2i = Vector2i(16, 24)
## Movement speed while worn, in pixels per second.
@export var speed: float = 62.0
## The light this friend throws while worn, and the colour of its essence.
@export var glow: Color = Color(0.85, 0.75, 1.0)
@export var glow_energy: float = 0.9
