class_name Tile
extends Node3D


@onready var view := $TileView
var type: int


func set_type(new_type: int) -> void:
	type = new_type
	# TODO: Adjust color based on type.
