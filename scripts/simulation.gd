class_name Simulation
extends Node3D


@export var tile: PackedScene
@export var rabbit: PackedScene
@export var grid_size: Vector2i
@export var spacing := 1.0
@export var init_rabbits := 10
@export_range(0.0, 1.0) var water_chance := 0.25
var tiles: Array[Tile]
var rabbits: Array[Rabbit]


func get_tile(x: int, y: int) -> Tile:
	return tiles[x * grid_size.y + y]
	
	
func get_random_tile() -> Tile:
	return tiles.pick_random() as Tile


func add_tile(x: int, y: int) -> Tile:
	var position := Vector3(x - grid_size.x / 2, 0.0, y - grid_size.y / 2)
	if grid_size.x % 2 == 0:
		position.x += 0.5
	if grid_size.y % 2 == 0:
		position.z += 0.5
	position *= spacing
	position = -position # Flip grid view.
	
	var new_tile := tile.instantiate() as Tile
	new_tile.name = "Tile_X{x}_Y{y}".format({"x": x, "y": y})
	new_tile.position = position
	new_tile.set_type(0 if randf() > water_chance else 1)
	
	add_child(new_tile)
	return new_tile


func add_rabbit(tile: Tile) -> Rabbit:
	var new_rabbit := rabbit.instantiate() as Rabbit
	new_rabbit.set_tile(tile)
	
	add_child(new_rabbit)
	return new_rabbit


func _ready() -> void:
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
