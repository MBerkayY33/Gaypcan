extends Node2D

const REFRESH_SPEED := 10.0 #increase to make game faster

const STEP_SIZE := 1.0/REFRESH_SPEED
var accumlation := 0.0
var map : Map

const ATLAS_COORD = [Vector2i(0,0),Vector2i(1,0)]

@onready var ground: TileMapLayer = $Ground

func _ready() -> void:
	print("ok")
	map = Map.new()
	map.test_lekesi()
	print(ground.tile_set)

	for y in map.Height:
		for x in map.Width:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	print(ground.get_used_cells().size())

	
func _process(delta: float) -> void:
	accumlation += delta
	while accumlation > (STEP_SIZE):
		accumlation -= (STEP_SIZE)
		var t := Time.get_ticks_usec()
		map.yayilim_fonksiyonu(STEP_SIZE)
		map.verim_guncelleme(STEP_SIZE)
		print((Time.get_ticks_usec() - t) / 1000.0, " ms")
		
		for i in map.degisenler:
			var x := i % map.Height
			var y := i / map.Width
			var tile_type = ATLAS_COORD[map.biome[i]]
			ground.set_cell(Vector2i(x,y),0, tile_type)
		map.degisenler.clear()
		
			
	
