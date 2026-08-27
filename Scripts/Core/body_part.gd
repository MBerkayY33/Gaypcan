@tool
extends RigidBody2D

## Modüler Vücut Parçası — Sınırsız Bağlantı Noktalı Fiziksel Parça
## 'Joints' node'unun altındaki tüm PinJoint2D'ler otomatik olarak algılanır.

# ==========================================
# SİNYALLER VE DEĞİŞKENLER
# ==========================================

signal slot_clicked(body_part: Node, slot_name: String, button_index: int) # Bir bağlantı noktasına tıklandığında tetiklenir
signal body_part_right_clicked(part: Node) # Parçanın kendisine sağ tıklandığında (silmek için) tetiklenir

@export_group("Hover Animation")
@export var plus_hover_scale: float = 1.3 # Üzerine gelindiğinde yeşil artının ne kadar büyüyeceği
@export var plus_hover_duration: float = 0.3 # Büyüme/küçülme animasyonunun süresi

@export_group("Physics & Visuals")
@export var spring_torque: float = 4000.0 # Parçanın sallanırken kendi orijinal açısına (T-Pose) dönme gücü

@export var is_ingame_editor_active: bool = false:
	set(v):
		is_ingame_editor_active = v
		_update_visuals() # Editör açılıp kapandığında görselleri anında güncelle
		
@export var hover_radius: float = 5.0 # Oyun içinde bağlantıların üst üste binip binmediğini (çakışma) tespit etme yarıçapı
@export var mouse_detect_radius: float = 20.0 # Farenin bağlantı noktasını algılama mesafesi (128x128 sprite için 20 idealdir)
@export var attach_offset: float = 35.0 # Yeni bağlanan parçanın merkezden ne kadar uzağa (dışarı) itileceği (128x128 için genelde 35'tir)

var tpose_offset: Vector2 = Vector2.ZERO # Başlangıçtaki lokal pozisyon (T-Pose durumu)
var original_freeze: bool = false # Başlangıçtaki dondurulma (freeze) durumunu hafızada tutar
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var _hover_tween: Tween
var _plus_original_scales: Dictionary = {} # Plus spritelarının orijinal boyutlarını tutar
var hovered_joint: String = "": # Farenin o an üzerinde olduğu bağlantı noktasının adı
	set(v):
		if hovered_joint != v:
			var old_joint = hovered_joint
			hovered_joint = v
			_update_hover_animation(old_joint, hovered_joint)

func _update_hover_animation(old_joint_name: String, new_joint_name: String) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		
	if old_joint_name != "":
		var old_joint = get_node_or_null("Joints/" + old_joint_name)
		if old_joint:
			var old_plus = old_joint.get_node_or_null("Plus")
			if old_plus:
				var orig_scale = _plus_original_scales.get(old_joint_name, Vector2(0.28, 0.28))
				old_plus.scale = orig_scale # Eski haline döndür
				
	if new_joint_name != "":
		var new_joint = get_node_or_null("Joints/" + new_joint_name)
		if new_joint:
			var new_plus = new_joint.get_node_or_null("Plus")
			if new_plus and new_plus.visible:
				if not _plus_original_scales.has(new_joint_name):
					_plus_original_scales[new_joint_name] = new_plus.scale
				var orig_scale = _plus_original_scales[new_joint_name]
				var target_scale = orig_scale * plus_hover_scale # Çarpan olarak kullanıyoruz
				
				_hover_tween = create_tween().set_loops()
				_hover_tween.tween_property(new_plus, "scale", target_scale, plus_hover_duration).set_trans(Tween.TRANS_SINE)
				_hover_tween.tween_property(new_plus, "scale", orig_scale, plus_hover_duration).set_trans(Tween.TRANS_SINE)

# ==========================================
# BAŞLATMA VE BAĞLANTI (JOINT) YÖNETİMİ
# ==========================================

## 'Joints' düğümü altındaki tüm PinJoint2D düğümlerinin isimlerini (Örn: Joint_1, Joint_2) dinamik olarak döndürür
func _get_all_joints() -> Array[String]:
	var list: Array[String] = []
	var joints_node = get_node_or_null("Joints")
	if joints_node:
		for child in joints_node.get_children():
			if child is Marker2D:
				list.append(child.name)
	return list

## Oyun başlarken veya sahne yüklenirken ilk hazırlıklar
func _ready() -> void:
	tpose_offset = position
	original_freeze = freeze
	
	# Eğer oyun çalışıyorsa ve parça hareketli bir uzuv ise (dondurulmamışsa)
	
	var joints_node = get_node_or_null("Joints")
	if joints_node:
		joints_node.z_as_relative = false
		joints_node.z_index = 50 # Her zaman parçaların üzerinde kalmasını garantile
	if not Engine.is_editor_hint():
		if not freeze:
			var g_pos = global_position
			var g_rot = global_rotation
			top_level = true # Ebeveynin hareketini kopyalama, tamamen fizikle sürüklen!
			global_position = g_pos
			global_rotation = g_rot
			can_sleep = false # Hareketsiz kaldığında uyku moduna geçip donmasını engeller
			
	# Fiziksel bağlantılar artık Connection sahnesi aracılığıyla Editor tarafından yönetilecek.

# ==========================================
# ÇAKIŞMA KONTROLÜ VE EKRANA ÇİZİM
# ==========================================

func _process(_delta: float) -> void:
	if is_dragging and is_ingame_editor_active:
		global_position = get_global_mouse_position() + drag_offset

func _physics_process(_delta: float) -> void:
	pass

func _update_visuals() -> void:
	for j_name in _get_all_joints():
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint: continue
		var spr_con = joint.get_node_or_null("Con_Point")
		var spr_plus = joint.get_node_or_null("Plus")
		var is_occupied = has_meta("occupied_" + j_name) and get_meta("occupied_" + j_name) == true
		
		if spr_con: spr_con.visible = is_ingame_editor_active
		if spr_plus: spr_plus.visible = is_ingame_editor_active and not is_occupied


# ==========================================
# FARE ETKİLEŞİMLERİ (INPUT)
# ==========================================

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false

## Fare ile noktaların üzerine gelme ve noktalara tıklama durumlarını yönetir
func _unhandled_input(event: InputEvent) -> void:
	if not is_ingame_editor_active:
		return
		
	# Fare hareketi: Hangi noktanın üzerinde olduğumuzu hesapla
	if event is InputEventMouseMotion:
		var local_mouse = get_local_mouse_position()
		var found_hover = ""
		var min_dist = mouse_detect_radius # En fazla bu kadar uzaktayken algılar
		
		for j_name in _get_all_joints():
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			var dist = local_mouse.distance_to(joint.position)
			if dist <= min_dist:
				found_hover = j_name
				min_dist = dist # Daha yakın bir tane bulduk, mesafe sınırını buna çek
					
		if hovered_joint != found_hover:
			hovered_joint = found_hover
			
	# Fare Tıklaması: Bir noktaya tıklandığında ekleme işlemlerini başlat (slot_clicked sinyali)
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		var local_mouse = get_local_mouse_position()
		
		var clicked_j_name = ""
		var min_dist = mouse_detect_radius
		for j_name in _get_all_joints():
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			var dist = local_mouse.distance_to(joint.position)
			if dist <= min_dist:
				clicked_j_name = j_name
				min_dist = dist
					
		if clicked_j_name != "":
			slot_clicked.emit(self, clicked_j_name, event.button_index)
			get_viewport().set_input_as_handled()
			return

## Parçanın kendisine sağ tıklandığını algılar (Silme menüsü için) veya sol tıklayıp sürüklemeyi başlatır
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not is_ingame_editor_active:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			body_part_right_clicked.emit(self)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
			else:
				is_dragging = false

# ==========================================
# EDİTÖR İÇİ HİZALAMA VE ANİMASYON
# ==========================================

## Fizik motorunun özel entegrasyonu (Yay etkisi yaratır)
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if Engine.is_editor_hint():
		return
	if freeze:
		return
		
	# Uzuvların hareket ederken hafifçe sallanıp sonra orijinal açılarına dönmesini (yaylanmasını) sağlar
	var target_rotation = 0.0
	var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
	
	state.apply_torque(angle_diff * spring_torque) # Dönüş açısına doğru güç uygula
	state.angular_velocity *= 0.90 # Sürekli dönmesini engellemek (sönümlemek) için yavaşlat

## Yürüme vb. animasyonları tetikleyen yardımcı fonksiyon
func play_animation(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		
	for child in get_children():
		if child.has_method("play_animation"):
			child.play_animation(anim_name)
