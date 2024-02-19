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
@export var seed := 0
@export var simulation_type := SimulationType.ANIMATED
@export var step_delay := 1.5
@export_range(0.0, 1.0) var female_percentage := 0.5

@export_group("References")
@export var rabbit_scene: PackedScene
@export var grass_scene: PackedScene
@export var tilemap: Tilemap
@export var a_star: AStar

@export_group("Grid settings")
@export var init_rabbits := 10
@export var init_grasses := 10
@export_range(0.0, 1.0) var water_chance := 0.25

var rng := RandomNumberGenerator.new()
var rabbits: Array[Rabbit]
var grasses: Array[Grass]
var timer := 0.0
var steps := 0


func add_rabbit(tile: Tile) -> Rabbit:
	var new_rabbit := rabbit_scene.instantiate() as Rabbit
	new_rabbit.name = "Rabbit_{i}".format({"i": rabbits.size()})
	new_rabbit.set_tile(tile, true)
	new_rabbit.set_gender(Rabbit.Gender.MALE if rng.randf() > female_percentage else Rabbit.Gender.FEMALE)
	add_child(new_rabbit)
	return new_rabbit


func add_grass(tile: Tile) -> Grass:
	var new_grass := grass_scene.instantiate() as Grass
	new_grass.set_tile(tile)
	add_child(new_grass)
	grasses.append(new_grass)
	return new_grass


func step() -> void:
	steps += 1
	
	for rabbit in rabbits:
		rabbit.step(simulation_type)
	
	for tile in tilemap.tiles:
		tile.step(steps)


func _ready() -> void:
	rng.seed = seed if (seed != 0) else randi_range(-65635, 65635)
	print("Simulation seed: {seed}".format({"seed": str(rng.seed)}))
	
	# Init tiles.
	for x in tilemap.size.x:
		for y in tilemap.size.y:
			var new_tile := tilemap.add_tile(x, y)
			new_tile.set_type(Tile.TileType.GROUND if rng.randf() > water_chance else Tile.TileType.WATER)
			new_tile.set_coords(x, y)
			new_tile.init_next_grass_timer()
			
	tilemap.init_neighbours()

	# Init rabbits.
	for i in init_rabbits:
		var rabbit_tile := tilemap.get_random_tile()
		while not rabbit_tile.can_add_rabbit():
			rabbit_tile = tilemap.get_random_tile()
		
		var new_rabbit = add_rabbit(rabbit_tile)
		rabbits.append(new_rabbit)

	# Init grass.
	for i in init_grasses:
		var grass_tile := tilemap.get_random_tile()
		while not grass_tile.can_add_grass():
			grass_tile = tilemap.get_random_tile()
		
		var new_grass = add_grass(grass_tile)
		
	for rabbit in rabbits:
		rabbit.init()

	if simulation_type == SimulationType.IMMEDIATE:
		# TODO: Implement this properly.
		print("TODO: Processing all simulation immediatly.")


func _process(delta: float) -> void:
	if simulation_type != SimulationType.IMMEDIATE and simulation_type != SimulationType.NONE:
		timer += delta
		if timer >= step_delay:
			step()
			timer = 0.0
