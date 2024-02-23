class_name Rabbit
extends Node3D


enum NeedType
{
	NONE,
	HUNGER,
	THIRST,
	REPRODUCTION,
}

enum Gender
{
	NONE = -1,
	MALE,
	FEMALE
}


@export_group("References")
@export var view_world: Node3D
@export var view_male: Node3D
@export var view_female: Node3D
@export var gauge_hunger: Gauge
@export var gauge_thirst: Gauge
@export var gauge_reproduction: Gauge

@export_group("Simulation settings")
@export var full_hunger_steps := 100
@export var full_thirst_steps := 50
@export var full_reproduction_steps := 50
@export var adult_age := 200
@export var full_age_steps_min_max := Vector2i(1000, 1200)

@export_group("View settings")
@export var height_offset := 0.5
@export var move_duration := 0.5
@export var min_age_scale := 0.2


@onready var simulation := get_parent() as Simulation
@onready var full_age_steps := simulation.rng.randi_range(full_age_steps_min_max.x, full_age_steps_min_max.y)
var tile: Tile
var gender := Gender.NONE
var age := 0

var current_need := NeedType.NONE
var hunger := 0.0
var thirst := 0.0
var reproduction := 0.0

var target_tile: Tile
var target_partner: Rabbit
var current_path: Array = []


func step(simulation_type: Simulation.SimulationType) -> void:
	age += 1
	if age > full_age_steps:
		kill()
		return
	
	set_need_value(NeedType.HUNGER, hunger + 1.0 / full_hunger_steps)
	set_need_value(NeedType.THIRST, thirst + 1.0 / full_thirst_steps)
	if gender == Gender.MALE and is_adult():
		set_need_value(NeedType.REPRODUCTION, reproduction + 1.0 / full_reproduction_steps)
	
	if current_need == NeedType.NONE:
		if hunger < 1.0 and hunger > 0.3:
			current_need = NeedType.HUNGER
			target_or_eat_closest_grass()
	if current_need == NeedType.NONE:
		if thirst < 1.0 and thirst > 0.1:
			current_need = NeedType.THIRST
			target_or_drink_closest_water()
	if current_need == NeedType.NONE:
		# TODO: if is adult.
		if gender == Gender.MALE and reproduction < 1.0 and reproduction > 0.5:
			current_need = NeedType.REPRODUCTION
			look_for_partner()

	# Refresh path to partner as it could be moving.
	if gender == Gender.MALE and target_partner != null:
		# TODO: check if target partner is not dead.
		current_path = simulation.a_star.try_find_path(self, tile, target_partner.tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
			current_path.remove_at(current_path.size() - 1)
	
	if current_path.size() > 0:
		var next_tile = current_path[0]
		if next_tile.rabbit != null:
			if current_need == NeedType.REPRODUCTION and next_tile.rabbit == target_partner:
				fulfill_need(NeedType.REPRODUCTION)
			else:
				current_path = simulation.a_star.try_find_path(self, tile, current_path[current_path.size() - 1])
				if current_path.size() > 0:
					next_tile = current_path.pop_front()
		if next_tile.rabbit == null:
			current_path.remove_at(0)
			set_tile(next_tile, simulation_type != Simulation.SimulationType.ANIMATED)
			
	update_age_size()
	
	if is_adult():
		gauge_reproduction.set_process(gender == Gender.MALE)
		gauge_reproduction.visible = gender == Gender.MALE


func kill() -> void:
	print("{r} death.".format({"r": name}))
	simulation.remove_rabbit(self)


func update_age_size() -> void:
	var to_adult_percentage := age / float(adult_age)
	to_adult_percentage = min(to_adult_percentage, 1.0)
	var scale = lerp(min_age_scale, 1.0, to_adult_percentage)
	view_world.scale = Vector3(1.0, 1.0, 1.0) * scale


func set_need_value(type: NeedType, value: float) -> void:
	if value >= 1.0:
		kill()
		return
		
	if type == NeedType.HUNGER:
		hunger = value
		gauge_hunger.set_value(hunger)
	elif type == NeedType.THIRST:
		thirst = value
		gauge_thirst.set_value(thirst)
	elif type == NeedType.REPRODUCTION:
		reproduction = value
		gauge_reproduction.set_value(reproduction)

func fulfill_need(type: NeedType) -> void:
	set_need_value(type, 0.0)
	current_path.clear()
	target_tile = null
	current_need = NeedType.NONE
	
	if type == NeedType.REPRODUCTION:
		target_partner.target_partner = null
		target_partner = null


func set_tile(new_tile: Tile, instantly: bool) -> void:
	if tile != null:
		tile.set_rabbit(null)
	tile = new_tile
	if tile != null:
		tile.set_rabbit(self)
	
	if instantly:
		view_world.look_at(tile.position + Vector3(0.0, height_offset, 0.0))
		position = tile.position
		position.y += height_offset
		on_tile_reached()
	else:
		move_to_tile(tile)


func set_gender(new_gender: Gender) -> void:
	gender = new_gender
	
	view_male.set_process(gender == Gender.MALE)
	view_male.visible = gender == Gender.MALE
	
	view_female.set_process(gender == Gender.FEMALE)
	view_female.visible = gender == Gender.FEMALE
	
	gauge_reproduction.set_process(gender == Gender.MALE and is_adult())
	gauge_reproduction.visible = gender == Gender.MALE and is_adult()


func is_adult() -> bool:
	return (age / float(adult_age)) >= 1.0


func move_to_tile(new_tile: Tile) -> void:
	var previous_position := position
	var target_position := new_tile.position + Vector3(0.0, height_offset, 0.0)
	view_world.look_at(target_position)
	
	var t := 0.0
	var time_step := 0.016
	while t < 1.0:
		await get_tree().create_timer(time_step).timeout
		t += time_step / move_duration
		position = Vector3((1.0 - t) * previous_position + t * target_position)
	
	position = Vector3(target_position)
	on_tile_reached()

func on_tile_reached() -> void:
	if current_need == NeedType.HUNGER and tile.grass != null:
		tile.grass.remove()
		fulfill_need(NeedType.HUNGER)
	elif current_need == NeedType.THIRST:
		if target_tile != null and current_path.size() == 0:
			fulfill_need(NeedType.THIRST)
	elif current_need == NeedType.REPRODUCTION:
		if target_partner != null and current_path.size() == 0:
			simulation.add_baby_rabbit(target_partner, self)
			fulfill_need(NeedType.REPRODUCTION)


func target_or_eat_closest_grass() -> void:
	var is_valid_grass_tile := func(t: Tile):
		return t.grass != null and t.grass.targetting_rabbit == null
		
	var target_grass_tile := simulation.tilemap.get_closest_tile(tile, is_valid_grass_tile)
	var target_grass := target_grass_tile.grass if target_grass_tile != null else null
	if target_grass == null:
		return
		
	if simulation.tilemap.tiles_distance(tile, target_grass_tile) == 0:
		tile.grass.remove()
		fulfill_need(NeedType.HUNGER)
		return
		
	target_grass.set_targetting_rabbit(self)
	target_tile = target_grass_tile
	
	current_path = simulation.a_star.try_find_path(self, tile, target_tile)
	if current_path.size() > 0:
		current_path.remove_at(0)
			
func target_or_drink_closest_water() -> void:
	var is_water := func(t: Tile):
		return t.type == Tile.TileType.WATER
		
	target_tile = simulation.tilemap.get_closest_tile(tile, is_water)
	if target_tile == null:
		return
	
	if simulation.tilemap.tiles_distance(tile, target_tile) == 1:
		fulfill_need(NeedType.THIRST)
		return
		
	current_path = simulation.a_star.try_find_path(self, tile, target_tile)
	if current_path.size() > 0:
		current_path.remove_at(0)
		current_path.remove_at(current_path.size() - 1)

func look_for_partner() -> void:
	if simulation.rabbits.size() <= 1:
		return
		
	var closest_partner: Rabbit
	var closest_partner_distance := (1 << 63) - 1
	
	for rabbit in simulation.rabbits:
		if rabbit == null:
			continue
		if rabbit.gender == gender or rabbit.target_partner != null:
			continue
		# TODO: minimum age condition.
		
		var to_rabbit := Vector2i(rabbit.tile.coords() - tile.coords())
		var rabbit_distance := to_rabbit.length()
		if rabbit_distance < closest_partner_distance:
			closest_partner_distance = rabbit_distance
			closest_partner = rabbit
	
	if closest_partner != null:
		# TODO: If partner is on a neighbouring tile, reproduce instantly.
		target_partner = closest_partner
		target_partner.target_partner = self
		current_path = simulation.a_star.try_find_path(self, tile, target_partner.tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
			current_path.remove_at(current_path.size() - 1)
