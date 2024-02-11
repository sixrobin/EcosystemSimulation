class_name Rabbit
extends Node3D


@export var height_offset := 0.5
var tile: Tile


func set_tile(new_tile: Tile, instantly: bool) -> void:
	if tile != null: tile.rabbit = null
	tile = new_tile
	if tile != null: tile.rabbit = self
	
	if instantly:
		position = tile.position
		position.y += height_offset
	else:
		move_to_tile(tile)


func move_to_tile(new_tile: Tile) -> void:
	var previous_position := position
	var t = 0.0
	var time_step = 0.016
	while t < 1.0:
		await get_tree().create_timer(time_step).timeout
		t += time_step
		position = (1.0 - t) * previous_position + t * new_tile.position
		position.y += height_offset
	
	position = tile.position
	position.y += height_offset
