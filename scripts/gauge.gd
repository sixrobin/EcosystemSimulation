class_name Gauge
extends Node3D


@export_group("References")
@export var slider: Node3D
@onready var init_scale := slider.scale.x


func set_value(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	slider.scale.x = init_scale * (1.0 - value)
