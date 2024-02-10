class_name Rabbit
extends Node3D


@export var height_offset := 0.5
var tile: Tile


func set_tile(new_tile: Tile) -> void:
	tile = new_tile
	position = tile.position + Vector3(0.0, height_offset, 0.0)
