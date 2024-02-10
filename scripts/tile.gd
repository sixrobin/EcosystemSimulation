class_name Tile
extends Node3D


enum TileType
{
	NONE,
	GRASS,
	WATER	
}


@export var view_grass: Node3D
@export var view_water: Node3D
var type: TileType
var rabbit: Rabbit


func can_add_rabbit() -> bool:
	return type == TileType.GRASS and rabbit == null


func set_type(new_type: TileType) -> void:
	type = new_type
	
	view_grass.set_process(new_type == TileType.GRASS)
	view_grass.visible = new_type == TileType.GRASS
	
	view_water.set_process(new_type == TileType.WATER)
	view_water.visible = new_type == TileType.WATER


func set_rabbit(new_rabbit: Rabbit) -> void:
	rabbit = new_rabbit
