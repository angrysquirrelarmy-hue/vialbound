## Render stack and the debug view.
##
## Everything is drawn into a 320x180 viewport and scaled up whole-number style;
## the post shader runs once over that small image. F3 walks back down the stack —
## full pass, lights only, raw sprites — which is the fastest way to tell whether
## something looks wrong because of the art or because of the shaders.
extends Node

enum Stage { RAW, LIT, FULL }

@onready var view: SubViewportContainer = $View
@onready var vp: SubViewport = $View/Viewport
@onready var hud: Label = $View/Viewport/HUD/Readout

var stage := Stage.FULL

## Frames to wait before a scripted capture, so lights and the follower have settled.
const SHOT_DELAY := 24

var _shot := -1
var _shot_stage := 0
var _shot_all := false

func _ready() -> void:
	Game.bracers[0] = load("res://data/species/glim.tres")
	Game.form_changed.connect(func(_s): _refresh())
	_apply_stage()
	_refresh()
	# `godot --path . -- --shot` writes the raw 320x180 frame to user://shot.png and quits.
	# `-- --shot-stages` writes one per pipeline stage. Used by the art review loop.
	var args := OS.get_cmdline_user_args()
	if args.has("--shot") or args.has("--shot-stages"):
		_shot_all = args.has("--shot-stages")
		if _shot_all:
			stage = Stage.RAW
			_apply_stage()
			_refresh()
		_shot = SHOT_DELAY

func _process(_delta: float) -> void:
	if _shot < 0:
		return
	_shot -= 1
	if _shot > 0:
		return
	await RenderingServer.frame_post_draw
	var name := "user://shot_%d.png" % _shot_stage if _shot_all else "user://shot.png"
	vp.get_texture().get_image().save_png(name)
	print("wrote ", name)
	if _shot_all and _shot_stage < 2:
		_shot_stage += 1
		stage = _shot_stage as Stage
		_apply_stage()
		_refresh()
		_shot = 4
	else:
		get_tree().quit()

func _unhandled_input(_e: InputEvent) -> void:
	if Input.is_action_just_pressed(&"debug_toggle"):
		stage = ((stage + 1) % Stage.size()) as Stage
		_apply_stage()
		_refresh()

func _apply_stage() -> void:
	var world := vp.get_node_or_null(^"World")
	if world == null:
		return
	view.material.set_shader_parameter(&"enabled", stage == Stage.FULL)
	var ambient := world.get_node_or_null(^"Ambient") as CanvasModulate
	if ambient:
		ambient.visible = stage != Stage.RAW
	var lights := world.get_node_or_null(^"Lights")
	if lights:
		lights.visible = stage != Stage.RAW
	var carried := world.get_node_or_null(^"Player/VialLight")
	if carried:
		carried.visible = stage != Stage.RAW

func _refresh() -> void:
	var form := Game.friend()
	var who := form.display_name + " (" + String(form.calling) + ")" if form else "yourself"
	hud.text = "%s  ·  %s\n1/2 wear  Q human  F3 stage" % [
		["raw sprites", "+ lights", "full pass"][stage], who]
