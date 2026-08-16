extends Camera2D
class_name DynamicCamera

@export_group("Kamera ve Zoom")

## Oyun modundayken kameranın temel yakınlığı.
@export var base_game_zoom: Vector2 = Vector2(1.0, 1.0)

## Editör modundayken kameranın temel yakınlığı.
@export var base_editor_zoom: Vector2 = Vector2(1.5, 1.5)

## Her bir aşamada kameranın ne kadar uzaklaşacağı (Örn: 0.88 = %12 uzaklaşır).
@export var zoom_factor_per_level: float = 0.88

## Kamera otomatik uzaklaşmadan önce kaç parça eklenmesi gerektiği.
@export var parts_per_zoom_level: int = 5

## Yaratığı ekrana sığdırırken köşelerde bırakılacak boşluk (tolerans) miktarı (piksel).
@export var safe_margin: float = 150.0

## Kameranın merkeze veya yeni yakınlık seviyesine geçerken ne kadar pürüzsüz/hızlı kayacağı.
@export var lerp_speed: float = 5.0

## Editör modunda fare tekerleğiyle yakınlaşma (zoom in) hassasiyeti (çarpılarak büyütülür).
@export var scroll_zoom_in_step: float = 1.1

## Editör modunda fare tekerleğiyle uzaklaşma (zoom out) hassasiyeti (bölünerek küçültülür, değer büyüdükçe daha hızlı uzaklaşır).
@export var scroll_zoom_out_step: float = 1.15

## Editörde fare tekerleğiyle uzaklaşılabilecek (zoom out) maksimum limit (1.0 = otomatik uzaklık, 0.4 = 2.5 kat daha uzak).
@export var min_manual_zoom_multiplier: float = 0.4

## Editörde fare tekerleğiyle yakınlaşılabilecek (zoom in) maksimum limit (1.0 = otomatik uzaklık, 2.5 = 2.5 kat daha yakın).
@export var max_manual_zoom_multiplier: float = 2.5


var current_zoom_level: int = 0
var target_zoom_level: int = 0
var manual_zoom_multiplier: float = 1.0
var was_editor_mode: bool = false

@onready var creature: Node = get_parent()

func _process(delta: float) -> void:
	_update_dynamic_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	var ingame_editor = creature.get_node_or_null("IngameEditor")
	var is_editor = false
	if ingame_editor and "is_editor_mode" in ingame_editor:
		is_editor = ingame_editor.is_editor_mode
		
	if is_editor and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			manual_zoom_multiplier *= scroll_zoom_in_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			manual_zoom_multiplier /= scroll_zoom_out_step
			
		manual_zoom_multiplier = clamp(manual_zoom_multiplier, min_manual_zoom_multiplier, max_manual_zoom_multiplier)

func _update_dynamic_camera(delta: float) -> void:
	var ingame_editor = creature.get_node_or_null("IngameEditor")
	
	var is_editor = false
	if ingame_editor and "is_editor_mode" in ingame_editor:
		is_editor = ingame_editor.is_editor_mode
		
	var body_parts_count = 0
	var all_parts = []
	for child in creature.get_children():
		if child is RigidBody2D and child.has_method("_update_joint"):
			body_parts_count += 1
			all_parts.append(child)
			
	# Temel aşama: parts_per_zoom_level kadar parçada 1 seviye (Örn: 5 parça = 1, 10 parça = 2)
	var base_level = int(body_parts_count / float(parts_per_zoom_level))
	var final_level = base_level
	
	var fit_level = 0
	var viewport_size = get_viewport_rect().size
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for part in all_parts:
		var pos = part.global_position
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
		
	# Merkez hesaplaması
	var bbox_center = Vector2.ZERO
	if all_parts.size() > 0:
		bbox_center = Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
	else:
		bbox_center = creature.global_position
		
	var bbox_width = max_x - min_x if all_parts.size() > 0 else 0
	var bbox_height = max_y - min_y if all_parts.size() > 0 else 0
		
	var required_width = bbox_width + safe_margin
	var required_height = bbox_height + safe_margin
	
	var current_base = base_editor_zoom if is_editor else base_game_zoom
	
	# Taşma varsa uygun seviyeyi (fit_level) hesapla
	while true:
		var test_zoom = current_base * pow(zoom_factor_per_level, fit_level)
		var visible_width = viewport_size.x / test_zoom.x
		var visible_height = viewport_size.y / test_zoom.y
		
		if required_width > visible_width or required_height > visible_height:
			fit_level += 1
		else:
			break
			
	# Hangisi daha yüksekse o seviyeyi kullan
	final_level = max(base_level, fit_level)
	
	if final_level != target_zoom_level:
		target_zoom_level = final_level
		
	if is_editor:
		if not was_editor_mode:
			# Editör moduna ilk geçişte, kameranın aniden sekmemesi için
			# nodu doğrudan şu anki ekran merkezine alıyoruz.
			global_position = get_screen_center_position()
			drag_horizontal_enabled = false
			drag_vertical_enabled = false
			position_smoothing_enabled = false
			
		# Editör modunda kameranın nodunu hedefe lerp ediyoruz
		global_position = global_position.lerp(bbox_center, lerp_speed * delta)
	else:
		if was_editor_mode:
			# Oyun moduna geri dönerken, cinemachine ayarlarını aç.
			drag_horizontal_enabled = true
			drag_vertical_enabled = true
			position_smoothing_enabled = true
			
		manual_zoom_multiplier = 1.0 # Oyun modunda manuel zoomu sıfırla
		# Oyun modunda nodu doğrudan merkeze yerleştiriyoruz,
		# sürüklenme ve yumuşatma açık olduğu için ekran sinematik şekilde takip edecektir.
		global_position = bbox_center
		
	was_editor_mode = is_editor
		
	# Zoom geçişini (Lerp) uygula
	var target_base_zoom = base_editor_zoom if is_editor else base_game_zoom
	var desired_zoom = target_base_zoom * pow(zoom_factor_per_level, target_zoom_level)
	if is_editor:
		desired_zoom *= manual_zoom_multiplier
		
	zoom = zoom.lerp(desired_zoom, lerp_speed * delta)
