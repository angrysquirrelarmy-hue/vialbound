## Session state. Autoloaded as `Game`.
##
## The prototype's rule holds: two bracers, three friends in the world, and you
## are either yourself or wearing one of the two bracer vials — never both.
extends Node

signal form_changed(species: Species)

const SLOTS := 2

var bracers: Array[Species] = [null, null]
## -1 means human form.
var active := -1

func friend() -> Species:
	return bracers[active] if active >= 0 and active < bracers.size() else null

func is_human() -> bool:
	return active < 0

func wear(slot: int) -> void:
	if slot < 0 or slot >= bracers.size() or bracers[slot] == null:
		return
	active = -1 if active == slot else slot   # pressing the same vial pours you back out
	form_changed.emit(friend())

func become_human() -> void:
	if active == -1:
		return
	active = -1
	form_changed.emit(null)
