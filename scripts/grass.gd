class_name Grass
extends Node3D


@export var height_offset := 0.5
var tile: Tile
var targetting_rabbit: Rabbit


func remove() -> void:
	var simulation := get_parent() as Simulation
	simulation.remove_grass(self)


func set_targetting_rabbit(rabbit: Rabbit) -> void:
	targetting_rabbit = rabbit


func set_tile(new_tile: Tile) -> void:
	if tile != null:
		tile.grass = null
	tile = new_tile
	if tile != null:
		tile.grass = self
	
	position = tile.position
	position.y += height_offset
