class_name Tile
extends Node3D


@export var view_grass: Node3D
@export var view_water: Node3D
var type: int
var rabbit: Rabbit


func can_add_rabbit() -> bool:
	return type == 0 and rabbit == null


func set_type(new_type: int) -> void:
	type = new_type
	
	view_grass.set_process(new_type == 0)
	view_grass.visible = new_type == 0
	
	view_water.set_process(new_type == 1)
	view_water.visible = new_type == 1


func set_rabbit(new_rabbit: Rabbit) -> void:
	rabbit = new_rabbit
