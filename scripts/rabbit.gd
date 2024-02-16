class_name Rabbit
extends Node3D


@export_group("References")
@export var view_world: Node3D
@export var gauge_hunger: Gauge
# TODO: gauge_thirst
# TODO: gauge_reproduction

@export_group("Settings")
@export var full_hunger_steps := 100
@export var height_offset := 0.5
@export var move_duration := 0.5

var simulation: Simulation
var tile: Tile
var hunger := 0.0
# TODO: thirst
# TODO: reproduction
var target_grass: Grass
var current_path: Array = []


func init() -> void:
	simulation = get_parent() as Simulation


func step(simulation_type: Simulation.SimulationType) -> void:
	set_hunger(hunger + 1.0 / full_hunger_steps)
	if hunger < 1.0 and hunger > 0.2: # TODO: Expose value.
		target_closest_grass()
	
	# TODO: thirst increase.
	# TODO: reproduction increase.
	
	if current_path != null and current_path.size() > 0:
		var next_tile = current_path.pop_front()
		set_tile(next_tile, simulation_type != Simulation.SimulationType.ANIMATED)


func kill() -> void:
	var rabbit_index := simulation.rabbits.find(self)
	simulation.rabbits.remove_at(rabbit_index)
	
	tile.rabbit = null
	queue_free()


func set_hunger(value: float) -> void:
	hunger = value
	if hunger >= 1.0:
		kill()
		return
	
	gauge_hunger.set_value(hunger)


func set_tile(new_tile: Tile, instantly: bool) -> void:
	if tile != null: tile.rabbit = null
	tile = new_tile
	if tile != null: tile.rabbit = self
	
	if instantly:
		view_world.look_at(tile.position + Vector3(0.0, height_offset, 0.0))
		position = tile.position
		position.y += height_offset
		on_tile_reached()
	else:
		move_to_tile(tile)


func move_to_tile(new_tile: Tile) -> void:
	var previous_position := position
	var target_position := new_tile.position + Vector3(0.0, height_offset, 0.0)
	view_world.look_at(target_position)
	
	var t := 0.0
	var time_step := 0.016
	while t < 1.0:
		await get_tree().create_timer(time_step).timeout
		t += time_step / move_duration
		position = Vector3((1.0 - t) * previous_position + t * target_position)
	
	position = Vector3(target_position)
	on_tile_reached()
		

func on_tile_reached() -> void:
	if tile.grass != null:
		tile.grass.eat(self)
		set_hunger(0.0)


func get_closest_grass() -> Grass:
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
	if target_grass != null:
		current_path = simulation.a_star.try_find_path(tile, target_grass.tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
