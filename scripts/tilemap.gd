class_name Tilemap
extends Node


@export_group("References")
@export var tile_scene: PackedScene

@export_group("Grid settings")
@export var size: Vector2i
@export var spacing := 1.0

var tiles: Array[Tile]


func get_tile(x: int, y: int) -> Tile:
	return tiles[x * size.y + y]


func get_random_tile() -> Tile:
	return tiles.pick_random() as Tile


func add_tile(x: int, y: int) -> Tile:
	var position := Vector3(x - size.x / 2.0, 0.0, y - size.y / 2.0)
	if size.x % 2 == 0:
		position.x += 0.5
	if size.y % 2 == 0:
		position.z += 0.5
	position *= spacing
	position = -position # Flip grid view.
	
	var new_tile := tile_scene.instantiate() as Tile
	new_tile.name = "Tile_X{x}_Y{y}".format({"x": x, "y": y})
	new_tile.position = position
	new_tile.simulation = get_parent() as Simulation
	
	tiles.append(new_tile)
	add_child(new_tile)
	
	return new_tile


func init_neighbours() -> void:
	for tile in tiles:
		if tile.x < size.x - 1:
			tile.add_neighbour(get_tile(tile.x + 1, tile.y))
		if tile.y < size.y - 1:
			tile.add_neighbour(get_tile(tile.x, tile.y + 1))
		if tile.x > 0:
			tile.add_neighbour(get_tile(tile.x - 1, tile.y))
		if tile.y > 0:
			tile.add_neighbour(get_tile(tile.x, tile.y - 1))
