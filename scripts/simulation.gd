class_name Simulation
extends Node3D


@export var tile: PackedScene
@export var grid_size: Vector2i
@export var spacing := 1.0

var tiles = []


func get_tile(x: int, y: int) -> Node3D:
	return tiles[x * grid_size.y + y]


func add_tile(x: int, y: int) -> Node3D:
	var position := Vector3(x - grid_size.x / 2, 0.0, y - grid_size.y / 2)
	if grid_size.x % 2 == 0: position.x += 0.5
	if grid_size.y % 2 == 0: position.z += 0.5
	position *= spacing
	position = -position # Flip grid view.
	
	var new_tile := tile.instantiate() as Node3D
	new_tile.name = "Tile_X{x}_Y{y}".format({"x": x, "y": y})
	new_tile.position = position
	add_child(new_tile)
	
	return new_tile


func _ready() -> void:
	for x in grid_size.x:
		for y in grid_size.y:
			var new_tile := add_tile(x, y)
			tiles.append(new_tile)