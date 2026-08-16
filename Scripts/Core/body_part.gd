@tool
extends RigidBody2D

## Modüler Vücut Parçası — 16 Bağlantı Noktalı Fiziksel Parça
## Her kenarında 4 adet eklem (PinJoint2D) bulunur.
## Inspector'dan hedef parçaları atayarak fiziksel bağlantı kurabilirsiniz.
## Inspector'dan hedef parçaları atayarak fiziksel bağlantı kurabilirsiniz.
## Editable Children açmanıza gerek yoktur.

signal slot_clicked(body_part: Node, slot_name: String, button_index: int)
signal body_part_right_clicked(part: Node)

@export var spring_torque: float = 4000.0 # Parçanın sallanırken kendi orijinal açısına (T-Pose) dönme gücü (Yaylanma/Sertlik)

var tpose_offset: Vector2 = Vector2.ZERO
var original_freeze: bool = false
var hovered_joint: String = ""
var is_fast_add_locked: bool = false

var is_ingame_editor_active: bool = false:
	set(v):
		is_ingame_editor_active = v
		queue_redraw()

var overlapped_joints: Array[String] = []

var _all_joints = [
	"Top_1", "Top_2", "Top_3", "Top_4", 
	"Bottom_1", "Bottom_2", "Bottom_3", "Bottom_4",
	"Left_1", "Left_2", "Left_3", "Left_4", 
	"Right_1", "Right_2", "Right_3", "Right_4"
]

# ==========================================
# FİZİKSEL ÇAKIŞMA (OVERLAP) KONTROLÜ
# ==========================================
func _physics_process(delta: float) -> void:
	if not is_ingame_editor_active:
		return
		
	overlapped_joints.clear()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0 # Noktanın etrafında 8 piksellik bir alan tarar
	query.shape = shape
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self.get_rid()]
	
	for j_name in _all_joints:
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint: continue
		
		# Sadece boş olan jointleri sorgula
		var target_path = get(j_name.to_lower())
		var is_connected = target_path != null and not target_path.is_empty()
		if is_connected: continue
		
		query.transform = Transform2D(0, joint.global_position)
		var results = space_state.intersect_shape(query)
		if results.size() > 0:
			overlapped_joints.append(j_name)
	
	# Noktaların güncel durumunu ekrana yansıt
	queue_redraw()

# ==========================================
# OYUN İÇİ EDİTÖR ÇİZİMİ VE TIKLAMA
# ==========================================
func _draw() -> void:
	if not is_ingame_editor_active:
		return
		
	for j_name in _all_joints:
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint:
			continue
			
		var target_path = get(j_name.to_lower())
		var is_connected = target_path != null and not target_path.is_empty()
		
		var color = Color.RED if is_connected else Color.WHITE
		
		if not is_connected and j_name in overlapped_joints:
			# Başka bir parçanın içinde kalan (çakışan) yuvalara çarpı çiz
			var p = joint.position
			draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), Color.RED, 2.0)
			draw_line(p + Vector2(4, -4), p + Vector2(-4, 4), Color.RED, 2.0)
		else:
			draw_circle(joint.position, 4.5, color) # Boyut 8.0'dan 4.5'e küçültüldü
			
			if j_name == hovered_joint:
				# Yeşil artı çiz
				var p = joint.position
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), Color.GREEN, 1.5)
				draw_line(p + Vector2(0, -3), p + Vector2(0, 3), Color.GREEN, 1.5)
				
				# Kilit aktifse ufak kırmızı kilit sembolü çiz
				if is_fast_add_locked:
					var lock_pos = p + Vector2(6, -6)
					draw_rect(Rect2(lock_pos, Vector2(5, 4)), Color.RED, true)
					draw_arc(lock_pos + Vector2(2.5, 0), 2.0, PI, TAU, 10, Color.RED, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if not is_ingame_editor_active:
		return
		
	if event is InputEventMouseMotion:
		var local_mouse = get_local_mouse_position()
		var found_hover = ""
		for j_name in _all_joints:
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			if local_mouse.distance_to(joint.position) <= 10.0:
				var target_path = get(j_name.to_lower())
				var is_connected = target_path != null and not target_path.is_empty()
				if not is_connected and not (j_name in overlapped_joints):
					found_hover = j_name
					break
					
		if hovered_joint != found_hover:
			hovered_joint = found_hover
			queue_redraw()
			
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		var local_mouse = get_local_mouse_position()
		
		for j_name in _all_joints:
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			if local_mouse.distance_to(joint.position) <= 10.0:
				var target_path = get(j_name.to_lower())
				var is_connected = target_path != null and not target_path.is_empty()
				if not is_connected:
					if j_name in overlapped_joints:
						# Çakışan noktalara tıklanmasını engelle
						get_viewport().set_input_as_handled()
						return
					slot_clicked.emit(self, j_name, event.button_index)
					get_viewport().set_input_as_handled()
				return

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not is_ingame_editor_active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		body_part_right_clicked.emit(self)
		get_viewport().set_input_as_handled()

# ==========================================
# TOP CONNECTIONS
# ==========================================
@export_group("Top Connections")

@export var top_1: NodePath:
	set(v):
		top_1 = v
		_update_joint("Top_1", v)

@export var top_2: NodePath:
	set(v):
		top_2 = v
		_update_joint("Top_2", v)

@export var top_3: NodePath:
	set(v):
		top_3 = v
		_update_joint("Top_3", v)

@export var top_4: NodePath:
	set(v):
		top_4 = v
		_update_joint("Top_4", v)

# ==========================================
# BOTTOM CONNECTIONS
# ==========================================
@export_group("Bottom Connections")

@export var bottom_1: NodePath:
	set(v):
		bottom_1 = v
		_update_joint("Bottom_1", v)

@export var bottom_2: NodePath:
	set(v):
		bottom_2 = v
		_update_joint("Bottom_2", v)

@export var bottom_3: NodePath:
	set(v):
		bottom_3 = v
		_update_joint("Bottom_3", v)

@export var bottom_4: NodePath:
	set(v):
		bottom_4 = v
		_update_joint("Bottom_4", v)

# ==========================================
# LEFT CONNECTIONS
# ==========================================
@export_group("Left Connections")

@export var left_1: NodePath:
	set(v):
		left_1 = v
		_update_joint("Left_1", v)

@export var left_2: NodePath:
	set(v):
		left_2 = v
		_update_joint("Left_2", v)

@export var left_3: NodePath:
	set(v):
		left_3 = v
		_update_joint("Left_3", v)

@export var left_4: NodePath:
	set(v):
		left_4 = v
		_update_joint("Left_4", v)

# ==========================================
# RIGHT CONNECTIONS
# ==========================================
@export_group("Right Connections")

@export var right_1: NodePath:
	set(v):
		right_1 = v
		_update_joint("Right_1", v)

@export var right_2: NodePath:
	set(v):
		right_2 = v
		_update_joint("Right_2", v)

@export var right_3: NodePath:
	set(v):
		right_3 = v
		_update_joint("Right_3", v)

@export var right_4: NodePath:
	set(v):
		right_4 = v
		_update_joint("Right_4", v)


# ==========================================
# YAŞAM DÖNGÜSÜ
# ==========================================

func _ready() -> void:
	tpose_offset = position
	original_freeze = freeze
	
	# Eğer oyun çalışıyorsa ve bu parça hareketli bir uzuv ise (Gövde değilse)
	if not Engine.is_editor_hint():
		if not freeze:
			var g_pos = global_position
			var g_rot = global_rotation
			top_level = true # Ebeveynin hareketini kopyalama, fizikle sürüklen!
			global_position = g_pos
			global_rotation = g_rot
			can_sleep = false # Hareketsizken uyku moduna geçip donmasını engelle
			
	# Tüm düğümler sahneye eklendikten sonra bağlantıları kur
	call_deferred("_apply_all_joints")


func _apply_all_joints() -> void:
	_update_joint("Top_1", top_1)
	_update_joint("Top_2", top_2)
	_update_joint("Top_3", top_3)
	_update_joint("Top_4", top_4)
	_update_joint("Bottom_1", bottom_1)
	_update_joint("Bottom_2", bottom_2)
	_update_joint("Bottom_3", bottom_3)
	_update_joint("Bottom_4", bottom_4)
	_update_joint("Left_1", left_1)
	_update_joint("Left_2", left_2)
	_update_joint("Left_3", left_3)
	_update_joint("Left_4", left_4)
	_update_joint("Right_1", right_1)
	_update_joint("Right_2", right_2)
	_update_joint("Right_3", right_3)
	_update_joint("Right_4", right_4)


# ==========================================
# EKLEM GÜNCELLEME
# ==========================================

## Inspector'dan atanan NodePath'i alıp, ilgili PinJoint2D'nin node_b'sine
## doğru yolu hesaplayarak atar.
func _update_joint(joint_name: String, target_path: NodePath) -> void:
	if not is_inside_tree():
		return

	var joint = get_node_or_null("Joints/" + joint_name)
	if not joint or not joint is PinJoint2D:
		return

	if target_path.is_empty():
		joint.node_b = NodePath("")
		return

	var target = get_node_or_null(target_path)
	if not target:
		return

	# Eğer bu hedef başka bir slota zaten atanmışsa, onu temizle (Aynı parçayı 2 yere bağlamayı engelle)
	_clear_duplicates(joint_name, target_path)

	# PinJoint2D'nin node_b'si, joint'in kendisine göre göreceli yol bekler.
	joint.node_b = joint.get_path_to(target)

# ==========================================
# EDİTÖR İÇİ HİZALAMA (SNAPPING)
# ==========================================
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_snap_all_attached_parts()

func _snap_all_attached_parts() -> void:
	var all_joints = [
		"Top_1", "Top_2", "Top_3", "Top_4", 
		"Bottom_1", "Bottom_2", "Bottom_3", "Bottom_4",
		"Left_1", "Left_2", "Left_3", "Left_4", 
		"Right_1", "Right_2", "Right_3", "Right_4"
	]
	
	for j_name in all_joints:
		var target_path = get(j_name.to_lower())
		if target_path and not target_path.is_empty():
			var target = get_node_or_null(target_path)
			var joint = get_node_or_null("Joints/" + j_name)
			if target and target is Node2D and joint:
				# Eklem yönüne göre parçanın dışa doğru offset'ini belirle (35 px merkezden kenara)
				var offset = Vector2.ZERO
				if j_name.begins_with("Top"): offset = Vector2(0, -35)
				elif j_name.begins_with("Bottom"): offset = Vector2(0, 35)
				elif j_name.begins_with("Left"): offset = Vector2(-35, 0)
				elif j_name.begins_with("Right"): offset = Vector2(35, 0)
				
				# Hedefin rotasyonunu hesaba katarak offset'i çevir
				var rotated_offset = offset.rotated(global_rotation)
				target.global_position = joint.global_position + rotated_offset

func _clear_duplicates(current_joint: String, target_path: NodePath) -> void:
	if target_path.is_empty():
		return
		
	var all_joints = [
		"Top_1", "Top_2", "Top_3", "Top_4", 
		"Bottom_1", "Bottom_2", "Bottom_3", "Bottom_4",
		"Left_1", "Left_2", "Left_3", "Left_4", 
		"Right_1", "Right_2", "Right_3", "Right_4"
	]
	
	for j_name in all_joints:
		if j_name == current_joint:
			continue
		var prop_name = j_name.to_lower()
		if get(prop_name) == target_path:
			# Eğer Inspector'da başka bir slot bu parçaya bakıyorsa onu boşalt
			set(prop_name, NodePath(""))
			var old_joint = get_node_or_null("Joints/" + j_name)
			if old_joint and old_joint is PinJoint2D:
				old_joint.node_b = NodePath("")

# ==========================================
# FİZİK VE SALLANMA ETKİSİ
# ==========================================
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if Engine.is_editor_hint():
		return
	if freeze:
		return
		
	# Uzuvların hareket ederken hafifçe sallanıp sonra orijinal açılarına dönmesini sağlar
	var target_rotation = 0.0
	var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
	
	# Yayı andıran bir tork uygula (Daha organik olması için)
	state.apply_torque(angle_diff * spring_torque)
	# Aşırı sallanmayı durdurmak için açısal sönümleme
	state.angular_velocity *= 0.90

# ==========================================
# ANİMASYON YÖNETİMİ
# ==========================================
func play_animation(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
