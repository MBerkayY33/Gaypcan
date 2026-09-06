extends Node2D


const REFRESH_SPEED := 10.0 #increase to make game faster

const STEP_SIZE := 1.0/REFRESH_SPEED
var accumlation := 0.0
var map : Map


@onready var panel: PanelContainer = $CanvasLayer/PanelContainer
@onready var label: Label = $CanvasLayer/PanelContainer/Label

#BİYOM EKLEME!!!!!!!!!!!!!
#biyom eklemek istiyosan tiles klasorune gel buyuk pngye istedigin biyomu ekle ekledigin biyomun koordinatini
#asagidaki atlasa ekle yanina da ne oldugunu not dus sonra map.gd de enuma ekle ismini ve sartlarini da verim
# guncelleme fonk'una yaz
const ATLAS_COORD = [
	Vector2i(1, 0),   # kahverengi
	Vector2i(0, 0),   # yeşil
]

const BIOM_NAME = ["earthy", "green"]

#tilemapi içeri aktarıyoruz(dolar sahnede ara demek)
@onready var ground: TileMapLayer = $Ground

func _ready() -> void:
	print("ok")
	map = Map.new()
	map.test_lekesi()
	print(ground.tile_set)
	var dorpak := ATLAS_COORD[Map.Biyom.earthy]
	for y in map.Height:
		for x in map.Width:
			ground.set_cell(Vector2i(x, y), 0, dorpak)
	print(ground.get_used_cells().size())
	
func _stat_window_update () -> void:
	var mouse_coordinates:= get_global_mouse_position()
	var cell := ground.local_to_map(ground.to_local(mouse_coordinates))
	var i =cell[0] + map.Width*cell[1]
	panel.visible = true
	label.text = "cell: %d, %d\nnem: %.3f\ngüneş: %.3f\nverim: %.3f\nbiyom: %s" % [
	cell.x, cell.y, map.nem[i], map.gunes[i], map.verim[i], BIOM_NAME[map.biome[i]]
	]
	if(not Input.is_key_pressed(KEY_SHIFT)):
		panel.visible = false
		return

	
func _process(delta: float) -> void:
	accumlation += delta
	_stat_window_update()
	


	while accumlation > (STEP_SIZE):
		accumlation -= (STEP_SIZE)
		var t := Time.get_ticks_usec()
		map.yayilim_fonksiyonu(STEP_SIZE)
		map.verim_guncelleme(STEP_SIZE)
		print((Time.get_ticks_usec() - t) / 1000.0, " ms")
		
		for i in map.degisenler:
			var x := i % map.Width
			var y := i / map.Width
			var tile_type = ATLAS_COORD[map.biome[i]]
			ground.set_cell(Vector2i(x,y),0, tile_type)
		map.degisenler.clear()
		
			
	
