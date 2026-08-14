extends Node2D

const REFRESH_SPEED := 10.0 #increase to make game faster

const STEP_SIZE := 1.0/REFRESH_SPEED
var accumlation := 0.0
var map : Map
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ok")
	map = Map.new()
	
	var ground := $Ground
	print(ground.tile_set)

	for y in map.Height:
		for x in map.Width:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	print(ground.get_used_cells().size())
	ground.set_cell(Vector2i(0, 0), 0, Vector2i(1, 0))
	ground.set_cell(Vector2i(1, 0), 0, Vector2i(1, 0))
	ground.set_cell(Vector2i(0, 1), 0, Vector2i(1, 0))
	
func _process(delta: float) -> void:
	accumlation += delta
	while accumlation > (STEP_SIZE):
		accumlation -= (STEP_SIZE)
		map.yayilim_fonksiyonu(STEP_SIZE)
	
