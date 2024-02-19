extends Node2D


@export var camera: Camera3D
@onready var simulation := get_parent() as Simulation


func draw_rabbits_targets() -> void:
	for rabbit in simulation.rabbits:
		var rabbit_target := rabbit.target_tile
		if rabbit_target == null:
			continue
		var rabbit_screen_pos := camera.unproject_position(rabbit.position)
		var rabbit_target_screen_pos := camera.unproject_position(rabbit_target.position)
		draw_line(rabbit_screen_pos, rabbit_target_screen_pos, Color.GREEN, 1.0)


func _draw() -> void:
	draw_rabbits_targets()


func _process(delta: float) -> void:
	queue_redraw()
