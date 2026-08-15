@tool
extends RigidBody2D

## Modüler Vücut Parçası — 16 Bağlantı Noktalı Fiziksel Parça
## Her kenarında 4 adet eklem (PinJoint2D) bulunur.
## Inspector'dan hedef parçaları atayarak fiziksel bağlantı kurabilirsiniz.
## Inspector'dan hedef parçaları atayarak fiziksel bağlantı kurabilirsiniz.
## Editable Children açmanıza gerek yoktur.

signal slot_clicked(body_part: Node, slot_name: String)

var is_ingame_editor_active: bool = false:
	set(v):
		is_ingame_editor_active = v
		queue_redraw()

var _all_joints = [
	"Top_1", "Top_2", "Top_3", "Top_4", 
	"Bottom_1", "Bottom_2", "Bottom_3", "Bottom_4",
	"Left_1", "Left_2", "Left_3", "Left_4", 
	"Right_1", "Right_2", "Right_3", "Right_4"
]

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
		draw_circle(joint.position, 8.0, color)

func _unhandled_input(event: InputEvent) -> void:
	if not is_ingame_editor_active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse = get_local_mouse_position()
		
		for j_name in _all_joints:
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			if local_mouse.distance_to(joint.position) <= 10.0:
				var target_path = get(j_name.to_lower())
				var is_connected = target_path != null and not target_path.is_empty()
				if not is_connected:
					slot_clicked.emit(self, j_name)
					get_viewport().set_input_as_handled()
				return

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
	
	# Yayı andıran bir tork uygula (Daha organik olması için azaltıldı)
	state.apply_torque(angle_diff * 4000.0)
	
	# Aşırı sallanmayı durdurmak için açısal sönümleme
	state.angular_velocity *= 0.90

# ==========================================
# ANİMASYON YÖNETİMİ
# ==========================================
func play_animation(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
