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

@export_group("Settings")
@export var full_hunger_steps := 100
@export var full_thirst_steps := 50
@export var full_reproduction_steps := 50
@export var height_offset := 0.5
@export var move_duration := 0.5

var simulation: Simulation
var tile: Tile
var gender := Gender.NONE

var current_need := NeedType.NONE
var hunger := 0.0
var thirst := 0.0
var reproduction := 0.0

var target_tile: Tile
var target_partner: Rabbit
var current_path: Array = []


func init() -> void:
	simulation = get_parent() as Simulation


func step(simulation_type: Simulation.SimulationType) -> void:
	set_hunger(hunger + 1.0 / full_hunger_steps)
	set_thirst(thirst + 1.0 / full_thirst_steps)
	if gender == Gender.MALE:
		set_reproduction(reproduction + 1.0 / full_reproduction_steps)
	
	if target_tile == null and target_partner == null:
		# TODO: expose values.
		if hunger < 1.0 and hunger > 0.3:
			current_need = NeedType.HUNGER
			target_closest_grass()
		elif thirst < 1.0 and thirst > 0.1:
			var closest_water := get_closest_water()
			if simulation.tilemap.tiles_distance(tile, closest_water) == 1:
				set_thirst(0.0)
				current_path.clear()
			else:
				current_need = NeedType.THIRST
				target_closest_water()
		elif gender == Gender.MALE and reproduction < 1.0 and reproduction > 0.5:
			current_need = NeedType.REPRODUCTION
			look_for_partner()
	
	if current_path != null and current_path.size() > 0:
		var next_tile = current_path.pop_front()
		set_tile(next_tile, simulation_type != Simulation.SimulationType.ANIMATED)
		
	# Refresh path to partner as it could be moving.
	if current_need == NeedType.REPRODUCTION and target_partner != null:
		current_path = simulation.a_star.try_find_path(tile, target_partner.tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
			current_path.remove_at(current_path.size() - 1)


func kill() -> void:
	var rabbit_index := simulation.rabbits.find(self)
	simulation.rabbits.remove_at(rabbit_index)
	
	tile.rabbit = null
	queue_free()


func set_hunger(value: float) -> void:
	hunger = value
	gauge_hunger.set_value(hunger)
	if hunger >= 1.0:
		kill()
		
func set_thirst(value: float) -> void:
	thirst = value
	gauge_thirst.set_value(thirst)
	if thirst >= 1.0:
		kill()

func set_reproduction(value: float) -> void:
	reproduction = value
	gauge_reproduction.set_value(reproduction)
	if reproduction >= 1.0:
		kill()
	

func set_tile(new_tile: Tile, instantly: bool) -> void:
	if tile != null: tile.set_rabbit(null)
	tile = new_tile
	if tile != null: tile.set_rabbit(self)
	
	if instantly:
		view_world.look_at(tile.position + Vector3(0.0, height_offset, 0.0))
		position = tile.position
		position.y += height_offset
		on_tile_reached()
	else:
		move_to_tile(tile)


func set_gender(new_gender: Gender):
	gender = new_gender
	
	view_male.set_process(gender == Gender.MALE)
	view_male.visible = gender == Gender.MALE
	
	view_female.set_process(gender == Gender.FEMALE)
	view_female.visible = gender == Gender.FEMALE
	
	gauge_reproduction.set_process(gender == Gender.MALE)
	gauge_reproduction.visible = gender == Gender.MALE


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
	if current_need == NeedType.HUNGER:
		if tile.grass != null:
			tile.grass.remove()
			set_hunger(0.0)
			target_tile = null
			current_need = NeedType.NONE
	elif current_need == NeedType.THIRST:
		if target_tile != null and current_path.size() == 0:
			set_thirst(0.0)
			current_path.clear()
			target_tile = null
			current_need = NeedType.NONE
	elif current_need == NeedType.REPRODUCTION:
		if target_partner != null and current_path.size() == 0:
			print("Partner found!")
			set_reproduction(0.0)
			current_path.clear()
			target_partner = null
			current_need = NeedType.NONE


func get_closest_grass(condition) -> Grass:
	if simulation.grasses.size() == 0:
		return null
		
	var closest_grass: Grass
	var closest_grass_distance := (1 << 63) - 1
	
	for grass in simulation.grasses:
		if not condition.call(grass):
			continue
		
		var to_grass := Vector2i(grass.tile.coords() - tile.coords())
		var grass_distance := to_grass.length()
		if grass_distance < closest_grass_distance:
			closest_grass_distance = grass_distance
			closest_grass = grass
	
	return closest_grass

func get_closest_water() -> Tile:
	var is_water := func(t):
		return t.type == Tile.TileType.WATER
	return simulation.tilemap.get_closest_tile(tile, is_water)

func target_closest_grass() -> void:
	var is_grass_available := func(g):
		return g.targetting_rabbit == null
	var closest_grass := get_closest_grass(is_grass_available)
	if closest_grass == null:
		return
		
	closest_grass.set_targetting_rabbit(self)
	target_tile = closest_grass.tile
	current_path = simulation.a_star.try_find_path(tile, target_tile)
	if current_path.size() > 0:
		current_path.remove_at(0)
			
func target_closest_water() -> void:
	target_tile = get_closest_water()
	if target_tile != null:
		current_path = simulation.a_star.try_find_path(tile, target_tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
			current_path.remove_at(current_path.size() - 1)

func look_for_partner() -> void:
	if simulation.rabbits.size() <= 1:
		return
		
	var closest_partner: Rabbit
	var closest_partner_distance := (1 << 63) - 1
	
	for rabbit in simulation.rabbits:
		if rabbit.gender == gender:
			continue
		# TODO: already reproducing condition.
		# TODO: minimum age condition.
		
		var to_rabbit := Vector2i(rabbit.tile.coords() - tile.coords())
		var rabbit_distance := to_rabbit.length()
		if rabbit_distance < closest_partner_distance:
			closest_partner_distance = rabbit_distance
			closest_partner = rabbit
	
	if closest_partner != null:
		# TODO: If partner is on a neighbouring tile, reproduce instantly.
		target_partner = closest_partner
		current_path = simulation.a_star.try_find_path(tile, target_partner.tile)
		if current_path.size() > 0:
			current_path.remove_at(0)
			current_path.remove_at(current_path.size() - 1)
