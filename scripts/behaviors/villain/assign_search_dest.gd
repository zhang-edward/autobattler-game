@tool
class_name AssignSearchDest
extends ActionLeaf

static var SEARCH_DEST_KEY = "SEARCH_DEST"
static var SEARCH_DEST_TS = "SEARCH_DEST_TS"
static var SEARCH_DEST_TTL = 4000

func tick(actor: Node, blackboard: Blackboard):
	var villain = actor as VillainTacticalEntity
	var search_dest_key = blackboard.get_value(SEARCH_DEST_KEY)
	if search_dest_key == null:
		update_search_dest(villain, blackboard)
	else:
		var search_dest_ts = blackboard.get_value(SEARCH_DEST_TS)
		if Time.get_ticks_msec() - search_dest_ts > SEARCH_DEST_TTL:
			update_search_dest(villain, blackboard)
	return SUCCESS

func update_search_dest(villain: VillainTacticalEntity, blackboard: Blackboard):
	blackboard.set_value(SEARCH_DEST_TS, Time.get_ticks_msec())
	var ground_layer = villain.game.ground_layer
	var coords_list: Array[Vector2i] = [
		Vector2i(9, 21),
		Vector2i(10, 21),
		Vector2i(10, 19),
		Vector2i(10, 20),
		Vector2i(1, 20)
	]
	var valid_tiles = get_matching_tiles_in_radius(ground_layer, villain.global_position, 400.0, 0, coords_list)
	var rand_tile_pos = ground_layer.map_to_local(valid_tiles.pick_random())
	blackboard.set_value(SEARCH_DEST_KEY, rand_tile_pos)
	return SUCCESS

func get_matching_tiles_in_radius(
	tilemap_layer: TileMapLayer,
	center_global_pos: Vector2, 
	radius_pixels: float, 
	target_source_id: int, 
	target_atlas_coords_list: Array[Vector2i]
) -> Array[Vector2i]:
	
	# Safety check to ensure the passed layer exists
	if not tilemap_layer or not tilemap_layer.tile_set:
		return []
		
	var matching_tiles: Array[Vector2i] = []
	
	# 1. Convert the center position to the specific layer's map coordinates
	var center_local_pos: Vector2 = tilemap_layer.to_local(center_global_pos)
	var center_map_pos: Vector2i = tilemap_layer.local_to_map(center_local_pos)
	
	# 2. Determine how many tiles we need to check in a bounding box grid based on pixel radius
	var tile_size: Vector2 = tilemap_layer.tile_set.tile_size
	var max_tile_offset_x: int = ceili(radius_pixels / tile_size.x)
	var max_tile_offset_y: int = ceili(radius_pixels / tile_size.y)
	
	# 3. Iterate through a square bounding box surrounding our center map position
	for x in range(-max_tile_offset_x, max_tile_offset_x + 1):
		for y in range(-max_tile_offset_y, max_tile_offset_y + 1):
			var current_cell: Vector2i = center_map_pos + Vector2i(x, y)
			
			# 4. Check if the individual tile's center falls inside the true pixel radius
			var cell_local_pos: Vector2 = tilemap_layer.map_to_local(current_cell)
			if center_local_pos.distance_to(cell_local_pos) <= radius_pixels:
				
				# 5. Check if the tile matches your specified ID and Atlas Coords
				var cell_source_id: int = tilemap_layer.get_cell_source_id(current_cell)
				var cell_atlas_coords: Vector2i = tilemap_layer.get_cell_atlas_coords(current_cell)
				
				if cell_source_id == target_source_id and cell_atlas_coords in target_atlas_coords_list:
					matching_tiles.append(current_cell)
	return matching_tiles
