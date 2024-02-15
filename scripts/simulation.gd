class_name Simulation
extends Node3D


enum SimulationType
{
	NONE,
	ANIMATED,
	INSTANT_STEPS,
	IMMEDIATE
}


@export_group("Simulation settings")
@export var simulation_type := SimulationType.ANIMATED
@export var step_delay := 1.5

@export_group("References")
@export var tile_scene: PackedScene
@export var rabbit_scene: PackedScene
@export var grass_scene: PackedScene

@export_group("Grid settings")
@export var grid_size: Vector2i
@export var spacing := 1.0
@export var init_rabbits := 10
@export var init_grasses := 10
@export_range(0.0, 1.0) var water_chance := 0.25

var tiles: Array[Tile]
var rabbits: Array[Rabbit]
var grasses: Array[Grass]
var timer := 0.0
var steps := 0


func get_tile(x: int, y: int) -> Tile:
	return tiles[x * grid_size.y + y]

func get_random_tile() -> Tile:
	return tiles.pick_random() as Tile


func a_star(src: Tile, dst: Tile) -> Array[Tile]:
	if src == dst:
		return [src, dst]
		
	for t in tiles:
		t.g_cost = 0
		t.h_cost = 0
	
	var close_set: Array[Tile]
	var open_set := [src]

	while open_set.size() > 0:
		var current = open_set.pop_front() as Tile
		if current == dst:
			return a_star_retrace(src, dst)

		close_set.append(current)

		for neighbour in current.neighbours:
			if close_set.has(neighbour):
				continue

			var neighbour_cost = neighbour.a_star_cost_to(current)
			if neighbour_cost == -1:
				continue
				
			var cost = current.g_cost + neighbour.a_star_cost_to(current)
			if cost < neighbour.g_cost or not open_set.has(neighbour):
				neighbour.g_cost = cost
				neighbour.h_cost = current.g_cost + neighbour.a_star_cost_to(current)
				neighbour.a_star_parent = current

				if not open_set.has(neighbour):
					open_set.append(neighbour)

	print("A* error: No path found!");
	return [null]

func a_star_retrace(src: Tile, dst: Tile) -> Array[Tile]:
	var path: Array[Tile]
	var current = dst
	
	while current != src:
		path.append(current)
		current = current.a_star_parent
		
	path.append(src)
	path.reverse()
	return path


func add_tile(x: int, y: int) -> Tile:
	var pos := Vector3(x - grid_size.x / 2.0, 0.0, y - grid_size.y / 2.0)
	if grid_size.x % 2 == 0:
		pos.x += 0.5
	if grid_size.y % 2 == 0:
		pos.z += 0.5
	pos *= spacing
	pos = -pos # Flip grid view.
	
	var new_tile := tile_scene.instantiate() as Tile
	new_tile.name = "Tile_X{x}_Y{y}".format({"x": x, "y": y})
	new_tile.position = pos
	new_tile.set_type(Tile.TileType.GROUND if randf() > water_chance else Tile.TileType.WATER)
	new_tile.set_coords(x, y)
	new_tile.init_next_grass_timer()
	
	add_child(new_tile)
	return new_tile

func add_rabbit(tile: Tile) -> Rabbit:
	var new_rabbit := rabbit_scene.instantiate() as Rabbit
	new_rabbit.set_tile(tile, true)
	add_child(new_rabbit)
	return new_rabbit
	
func add_grass(tile: Tile) -> Grass:
	var new_grass := grass_scene.instantiate() as Grass
	new_grass.set_tile(tile)
	add_child(new_grass)
	return new_grass


func step() -> void:
	steps += 1
	
	for r in rabbits:
		r.step(simulation_type)
	
	for t in tiles:
		t.step(steps)


func _ready() -> void:
	# TODO: initialize random seed.
	
	# Init tiles.
	for x in grid_size.x:
		for y in grid_size.y:
			var new_tile := add_tile(x, y)
			tiles.append(new_tile)

	# Init tiles neighbours.
	for t in tiles:
		if t.x < grid_size.x - 1:
			t.add_neighbour(get_tile(t.x + 1, t.y))
		if t.y < grid_size.y - 1:
			t.add_neighbour(get_tile(t.x, t.y + 1))
		if t.x > 0:
			t.add_neighbour(get_tile(t.x - 1, t.y))
		if t.y > 0:
			t.add_neighbour(get_tile(t.x, t.y - 1))

	# Init rabbits.
	for i in init_rabbits:
		var rabbit_tile := get_random_tile()
		while not rabbit_tile.can_add_rabbit():
			rabbit_tile = get_random_tile()
		
		var new_rabbit = add_rabbit(rabbit_tile)
		rabbits.append(new_rabbit)

	# Init grass.
	for i in init_grasses:
		var grass_tile := get_random_tile()
		while not grass_tile.can_add_grass():
			grass_tile = get_random_tile()
		
		var new_grass = add_grass(grass_tile)
		grasses.append(new_grass)
		
	for r in rabbits:
		r.target_closest_grass()

	if simulation_type == SimulationType.IMMEDIATE:
		# TODO: Implement this properly.
		print("TODO: Processing all simulation immediatly.")


func _process(delta: float) -> void:
	if simulation_type != SimulationType.IMMEDIATE and simulation_type != SimulationType.NONE:
		timer += delta
		if timer >= step_delay:
			step()
			timer = 0.0
