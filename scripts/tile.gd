class_name Tile
extends Node3D


enum TileType
{
	NONE,
	GROUND,
	WATER	
}


@export_group("References")
@export var view_grass: Node3D
@export var view_water: Node3D

@export_group("Settings")
@export var next_grass_timer_min_max := Vector2i(5, 25)
@export var discard_grass := false

var simulation: Simulation
var type: TileType
var x := -1
var y := -1
var neighbours: Array[Tile]
var rabbit: Rabbit
var grass: Grass
var steps_until_grass := -1

# A* variables.
var is_a_star_available := true
var a_star_parent: Tile
var g_cost := 0
var h_cost := 0


func coords() -> Vector2i:
	return Vector2i(x, y)
	

func add_neighbour(new_neighbour: Tile) -> void:
	neighbours.append(new_neighbour)


func step(total_steps: int) -> void:
	if steps_until_grass > 0:
		steps_until_grass -= 1
		if steps_until_grass == 0:
			steps_until_grass = -1
			if can_add_grass():
				simulation.add_grass(self)


func a_star_cost_to(agent, neighbour: Tile) -> int:
	if neighbour.type == TileType.WATER:
		return -1
	if neighbour.rabbit != null and agent != neighbour.rabbit:
		return -1
	return 1


func init_next_grass_timer() -> int:
	var timer_min = next_grass_timer_min_max.x
	var timer_max = next_grass_timer_min_max.y
	steps_until_grass = simulation.rng.randi_range(timer_min, timer_max)
	return steps_until_grass


func can_add_rabbit() -> bool:
	return type == TileType.GROUND and rabbit == null and grass == null

func can_add_grass() -> bool:
	if discard_grass:
		return false
	return type == TileType.GROUND and rabbit == null and grass == null


func set_coords(new_x: int, new_y: int) -> void:
	x = new_x
	y = new_y

func set_type(new_type: TileType) -> void:
	type = new_type
	
	view_grass.set_process(new_type == TileType.GROUND)
	view_grass.visible = new_type == TileType.GROUND
	
	view_water.set_process(new_type == TileType.WATER)
	view_water.visible = new_type == TileType.WATER

func set_rabbit(new_rabbit: Rabbit) -> void:
	rabbit = new_rabbit
