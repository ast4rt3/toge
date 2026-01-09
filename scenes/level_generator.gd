extends Node2D

@export var map_width = 100
@export var map_height = 100
@export var room_count = 10
@export var min_room_size = 6
@export var max_room_size = 12
@export var enemy_count_per_room = 2

var floor_scene = preload("res://scenes/Floor.tscn")
var wall_scene = preload("res://scenes/Wall.tscn")
var player_scene = preload("res://scenes/Player.tscn")
var enemy_scene = preload("res://scenes/Enemy.tscn")

var tile_size = 32

func _ready():
	generate_level()

func generate_level():
	var rooms = []
	var floor_tiles = {} # Dictionary of Vector2i -> true
	
	for i in range(room_count):
		# Try to place a non-overlapping room
		var room = create_random_room(rooms)
		if room:
			rooms.append(room)
			carve_room(room, floor_tiles)
			
			if i > 0:
				# Connect to previous room
				var prev_room = rooms[rooms.size() - 2]
				carve_corridor(prev_room.get_center(), room.get_center(), floor_tiles)

	var barrier_scene = preload("res://scenes/Barrier.tscn")

	# Instantiate Floors
	for pos in floor_tiles.keys():
		var f = floor_scene.instantiate()
		f.position = Vector2(pos) * tile_size
		add_child(f)
		
		# If this tile is inside the first room (Safe Zone), add a Barrier
		if rooms.size() > 0 and rooms[0].has_point(pos):
			var b = barrier_scene.instantiate()
			b.position = Vector2(pos) * tile_size
			add_child(b)

	# Instantiate Walls (Perimeter)
	generate_walls(floor_tiles)

	# Spawn Content
	if rooms.size() > 0:
		spawn_player(rooms[0])
		
		# Spawn Enemies in all other rooms
		for i in range(1, rooms.size()):
			spawn_enemies(rooms[i])

func create_random_room(existing_rooms):
	var max_attempts = 10
	for attempt in max_attempts:
		var w = randi_range(min_room_size, max_room_size)
		var h = randi_range(min_room_size, max_room_size)
		var x = randi_range(0, map_width - w)
		var y = randi_range(0, map_height - h)
		
		var new_rect = Rect2i(x, y, w, h)
		
		# Check overlap (with padding)
		var intersects = false
		for room in existing_rooms:
			if room.grow(1).intersects(new_rect):
				intersects = true
				break
		
		if not intersects:
			return new_rect
	return null

func carve_room(rect: Rect2i, tiles_dict: Dictionary):
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			tiles_dict[Vector2i(x, y)] = true

func carve_corridor(start: Vector2i, end: Vector2i, tiles_dict: Dictionary):
	# Horizontal then Vertical
	var current = start
	while current.x != end.x:
		tiles_dict[current] = true
		current.x += 1 if end.x > current.x else -1
	
	while current.y != end.y:
		tiles_dict[current] = true
		current.y += 1 if end.y > current.y else -1
		
	tiles_dict[end] = true

func generate_walls(floor_tiles: Dictionary):
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, 
					  Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)] # basics + corners
	
	var wall_positions = {}
	
	for pos in floor_tiles.keys():
		for dir in directions:
			var neighbor = pos + dir
			if not floor_tiles.has(neighbor) and not wall_positions.has(neighbor):
				var w = wall_scene.instantiate()
				w.position = Vector2(neighbor) * tile_size
				add_child(w)
				wall_positions[neighbor] = true

func spawn_player(room: Rect2i):
	var p = player_scene.instantiate()
	p.position = room.get_center() * tile_size
	add_child(p)

func spawn_enemies(room: Rect2i):
	var count = randi_range(1, enemy_count_per_room)
	for i in range(count):
		# Random pos within room, avoiding walls
		var x = randi_range(room.position.x + 1, room.end.x - 2)
		var y = randi_range(room.position.y + 1, room.end.y - 2)
		var pos = Vector2i(x, y)
		
		var e = enemy_scene.instantiate()
		e.position = Vector2(pos) * tile_size
		add_child(e)
