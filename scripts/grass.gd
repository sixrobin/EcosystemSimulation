class_name Grass
extends Node3D


@export var height_offset := 0.5
var tile: Tile


func eat(rabbit: Rabbit) -> void:
	tile.init_next_grass_timer()
	
	var simulation := get_parent() as Simulation
	var grass_index := simulation.grasses.find(self)
	simulation.grasses.remove_at(grass_index)
	
	tile.grass = null
	queue_free()


func set_tile(new_tile: Tile) -> void:
	if tile != null: tile.grass = null
	tile = new_tile
	if tile != null: tile.grass = self
	
	position = tile.position
	position.y += height_offset
