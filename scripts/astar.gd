class_name AStar
extends Node


var simulation: Simulation


func try_find_path(agent, src: Tile, dst: Tile) -> Array:
	if src == dst:
		return [src, dst]
		
	for tile in simulation.tilemap.tiles:
		tile.g_cost = 0
		tile.h_cost = 0
	
	var close_set: Array = []
	var open_set := [src]

	while open_set.size() > 0:
		var current := open_set.pop_front() as Tile
		if current == dst:
			return retrace(src, dst)

		close_set.append(current)

		for neighbour in current.neighbours:
			if close_set.has(neighbour):
				continue

			var neighbour_cost := neighbour.a_star_cost_to(agent, current)
			if neighbour_cost == -1:
				continue
				
			var cost := current.g_cost + neighbour_cost
			if cost < neighbour.g_cost or not open_set.has(neighbour):
				neighbour.g_cost = cost
				neighbour.h_cost = current.g_cost + neighbour_cost
				neighbour.a_star_parent = current

				if not open_set.has(neighbour):
					open_set.append(neighbour)

	return []


func retrace(src: Tile, dst: Tile) -> Array:
	var path: Array = []
	var current := dst
	
	while current != src:
		path.append(current)
		current = current.a_star_parent
		
	path.append(src)
	path.reverse()
	return path


func _ready() -> void:
	simulation = get_parent() as Simulation
