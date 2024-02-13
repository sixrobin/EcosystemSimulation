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

func get_random_neighbour_tile(tile: Tile) -> Tile:
	var direction := randi_range(0, 3)
	var result: Tile
	
	# TODO: working first draft for such a method, although a much better way
	# would be to loop through shuffled neighbours and get the first
	# available one. This would allow the method to take a lambda condition.
	
	if direction == 0 and tile.x < grid_size.x - 1:
		result = get_tile(tile.x + 1, tile.y)
	elif direction == 1 and tile.y < grid_size.y - 1:
		result = get_tile(tile.x, tile.y + 1)
	elif direction == 2 and tile.x > 0:
		result = get_tile(tile.x - 1, tile.y)
	elif direction == 3 and tile.y > 0:
		result = get_tile(tile.x, tile.y - 1)
	
	return result

func a_star(src: Tile, dst: Tile) -> Array[Tile]:
	if src == dst:
		return [src, dst]
		
	# TODO: Reset all nodes costs.
	
	var close_set: Array[Tile]
	var open_set := [src]

	while open_set.size() > 0:
		var current = open_set.pop_front() as Tile

		if current == dst:
			return a_star_retrace(src, dst)

		close_set.append(current)

		# TODO: Handle costs in tile.gd.
		for neighbour in current.neighbours:
			if not neighbour.IsNodeAvailable or close_set.has(neighbour):
				continue

			var neighbour_cost = current.GCost + neighbour.CostToNode(current);

			if neighbour_cost < neighbour.GCost or not open_set.has(neighbour):
				neighbour.GCost = neighbour_cost
				neighbour.HCost = current.GCost + neighbour.CostToNode(current)
				neighbour.ParentNode = current

				if not open_set.has(neighbour):
					open_set.append(neighbour)

	print("A* error: No path found!");
	return [null] # TMP.

func a_star_retrace(src: Tile, dst: Tile) -> Array[Tile]:
	return [null]


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
	
	for rabbit in rabbits:
		var new_tile := get_random_neighbour_tile(rabbit.tile)
		var iterations := 0
		while new_tile == null or not new_tile.can_add_rabbit():
			new_tile = get_random_neighbour_tile(rabbit.tile)
			iterations += 1
			if iterations == 100:
				break
		
		if iterations < 100:
			rabbit.set_tile(new_tile, simulation_type != SimulationType.ANIMATED)
	
	for tile in tiles:
		tile.step(steps)


func _ready() -> void:
	# TODO: initialize random seed.
	
	for x in grid_size.x:
		for y in grid_size.y:
			var new_tile := add_tile(x, y)
			tiles.append(new_tile)

	for i in init_rabbits:
		var rabbit_tile := get_random_tile()
		while not rabbit_tile.can_add_rabbit():
			rabbit_tile = get_random_tile()
			
		var new_rabbit = add_rabbit(rabbit_tile)
		rabbits.append(new_rabbit)
		
	for i in init_grasses:
		var grass_tile := get_random_tile()
		while not grass_tile.can_add_grass():
			grass_tile = get_random_tile()
			
		var new_grass = add_grass(grass_tile)
		grasses.append(new_grass)
	
	if simulation_type == SimulationType.IMMEDIATE:
		# TODO: Implement this properly.
		print("TODO: Processing all simulation immediatly.")


func _process(delta: float) -> void:
	if simulation_type != SimulationType.IMMEDIATE and simulation_type != SimulationType.NONE:
		timer += delta
		if timer >= step_delay:
			step()
			timer = 0.0
