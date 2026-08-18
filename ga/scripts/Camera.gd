extends Camera2D

@export var zoom_rate := 0.1
@export var camera_speed = 600
@export var ground: TileMapLayer
@export var _zoom_min := 0.1
@export var _zoom_max := 4.0
@onready var Tile_pixel_size = ground.tile_set.tile_size.x

func _ready() -> void:
	limit_left = 0
	limit_top = 0

	limit_right = Map.Width*Tile_pixel_size
	limit_bottom = Map.Height*Tile_pixel_size
	_zoom_sinirla()

func _process(delta:float) -> void:
	if Input.is_key_pressed(KEY_W):
		position.y-= camera_speed*delta/zoom.x    
	if Input.is_key_pressed(KEY_A):
		position.x -= camera_speed*delta/zoom.x
	if Input.is_key_pressed(KEY_S):
		position.y += camera_speed*delta/zoom.x
	if Input.is_key_pressed(KEY_D):
		position.x += camera_speed*delta/zoom.x

			
func  _unhandled_input(event: InputEvent): # olay gelince otomatik calısıyo bu fonk
	
	if event is InputEventMouseButton and event.pressed:
		print("olay: ", event.button_index, "  zoom: ", zoom)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= (1+zoom_rate)
			_zoom_sinirla()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= (1-zoom_rate)
			_zoom_sinirla()
			
func _zoom_sinirla() -> void:
	var vp := get_viewport_rect().size
	var en_az_x := vp.x / float(Map.Width * Tile_pixel_size)
	var en_az_y := vp.y / float(Map.Height * Tile_pixel_size)
	_zoom_min = max(en_az_x, en_az_y)

	var yeni := clampf(zoom.x, _zoom_min, _zoom_max)
	zoom = Vector2(yeni, yeni)
