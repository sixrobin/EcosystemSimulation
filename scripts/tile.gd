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

var type: TileType
var x := -1
var y := -1
var rabbit: Rabbit
var grass: Grass


func can_add_rabbit() -> bool:
	return type == TileType.GROUND and rabbit == null and grass == null

func can_add_grass() -> bool:
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
