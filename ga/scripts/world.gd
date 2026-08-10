extends Node2D

var map : Map
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ok")
	map = Map.new()
	
	var ground := $Ground
	print(ground.tile_set)

	for x in map.Width:
		for y in map.Height:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	print(ground.get_used_cells().size())
			
