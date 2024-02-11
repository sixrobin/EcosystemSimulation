class_name Grass
extends Node3D


@export var height_offset := 0.5
var tile: Tile


func set_tile(new_tile: Tile) -> void:
	if tile != null: tile.grass = null
	tile = new_tile
	if tile != null: tile.grass = self
	
	position = tile.position
	position.y += height_offset
