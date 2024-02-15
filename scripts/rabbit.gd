class_name Rabbit
extends Node3D


@export var height_offset := 0.5
@export var move_duration := 0.5

var tile: Tile
var target_grass: Grass
var current_path: Array = []


func step(simulation_type: Simulation.SimulationType) -> void:
	if current_path != null and current_path.size() > 0:
		var next_tile = current_path.pop_front()
		set_tile(next_tile, simulation_type != Simulation.SimulationType.ANIMATED)


func set_tile(new_tile: Tile, instantly: bool) -> void:
	if tile != null: tile.rabbit = null
	tile = new_tile
	if tile != null: tile.rabbit = self
	
	if instantly:
		look_at(tile.position + Vector3(0.0, height_offset, 0.0))
		position = tile.position
		position.y += height_offset
		on_tile_reached()
	else:
		move_to_tile(tile)


func move_to_tile(new_tile: Tile) -> void:
	var previous_position := position
	var target_position = new_tile.position + Vector3(0.0, height_offset, 0.0)
	look_at(target_position)
	
	var t := 0.0
	var time_step = 0.016
	while t < 1.0:
		await get_tree().create_timer(time_step).timeout
		t += time_step / move_duration
		position = (1.0 - t) * previous_position + t * target_position
	
	position = target_position
	on_tile_reached()
		

func on_tile_reached() -> void:
	if tile.grass != null:
		tile.grass.eat(self)
		target_closest_grass()


func get_closest_grass() -> Grass:
	var simulation := get_parent() as Simulation
	
	if simulation.grasses.size() == 0:
		return null
		
	var closest_grass: Grass
	var closest_grass_distance := (1 << 63) - 1
	
	for grass in simulation.grasses:
		var to_grass := Vector2i(grass.tile.coords() - tile.coords())
		var grass_distance := to_grass.length()
		if grass_distance < closest_grass_distance:
			closest_grass_distance = grass_distance
			closest_grass = grass
	
	return closest_grass

func target_closest_grass() -> void:
	target_grass = get_closest_grass()
	if target_grass == null:
		return
	var simulation := get_parent() as Simulation
	current_path = simulation.a_star.try_find_path(tile, target_grass.tile)
	if current_path.size() > 0:
		current_path.remove_at(0)
