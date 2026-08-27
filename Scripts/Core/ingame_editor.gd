extends Node
class_name IngameEditor

var is_editor_mode: bool = false
var editor_ui: CanvasLayer

var editor_menu: PanelContainer
var delete_menu: PanelContainer
var tools_panel: PanelContainer

var is_placing_body_part: bool = false
var part_being_placed: Node
var is_drawing_connection: bool = false
var draw_connection_line: Line2D

var last_clicked_part: Node
var last_clicked_slot: String
var part_to_delete: Node

@onready var creature: Creature = get_parent() as Creature

func _ready() -> void:
	_setup_editor_ui()
	# Bir frame bekle ki tüm body partlar hazır olsun
	call_deferred("_connect_existing_parts", creature)

func _setup_editor_ui() -> void:
	editor_ui = creature.get_node_or_null("editor_canvas")
	if not editor_ui:
		return
		
	# Kullanıcının eklediği panelleri bul
	editor_menu = editor_ui.get_node_or_null("Con_Point_Panel")
	if editor_menu:
		editor_menu.hide()
		var add_body_btn = editor_menu.get_node_or_null("VBoxContainer/Add_Body_Button")
		if add_body_btn and not add_body_btn.pressed.is_connected(_add_body_part_logic): 
			add_body_btn.pressed.connect(_add_body_part_logic)
			
		var connect_part_btn = editor_menu.get_node_or_null("VBoxContainer/Connect_Part_Button")
		if connect_part_btn and not connect_part_btn.pressed.is_connected(_connect_part_logic):
			connect_part_btn.pressed.connect(_connect_part_logic)
			
		var draw_conn_btn = editor_menu.get_node_or_null("VBoxContainer/Draw_Connection_Button")
		if draw_conn_btn and not draw_conn_btn.pressed.is_connected(_start_drawing_connection):
			draw_conn_btn.pressed.connect(_start_drawing_connection)
		
		var add_limb_btn = editor_menu.get_node_or_null("VBoxContainer/Add_Part_Button")
		if add_limb_btn: add_limb_btn.pressed.connect(func(): editor_menu.hide())
		
	delete_menu = editor_ui.get_node_or_null("Body_Part_Panel")
	if delete_menu:
		delete_menu.hide()
		var del_btn = delete_menu.get_node_or_null("VBoxContainer/Delete_Bodypart_Button")
		if del_btn: del_btn.pressed.connect(_on_delete_part_pressed)
		
		var prop_btn = delete_menu.get_node_or_null("VBoxContainer/Properties_Button")
		if prop_btn: prop_btn.pressed.connect(func(): delete_menu.hide())
		
	tools_panel = editor_ui.get_node_or_null("Editor_Tools_Panel")
	if tools_panel:
		tools_panel.hide()
		var add_body_tool = tools_panel.get_node_or_null("VBoxContainer/Add_Body")
		if add_body_tool and not add_body_tool.pressed.is_connected(_start_placing_new_body):
			add_body_tool.pressed.connect(_start_placing_new_body)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_toggle_editor_mode()
	
	# Boşluğa tıklanınca açık olan menüleri gizle
	if is_editor_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_drawing_connection:
			_finish_drawing_connection()
			get_viewport().set_input_as_handled()
			return
			
		if is_placing_body_part:
			_place_body_part()
			get_viewport().set_input_as_handled()
			return
			
		var m_pos = get_viewport().get_mouse_position()
		if editor_menu and editor_menu.visible and not editor_menu.get_global_rect().has_point(m_pos):
			editor_menu.hide()
		if delete_menu and delete_menu.visible and not delete_menu.get_global_rect().has_point(m_pos):
			delete_menu.hide()

func _process(_delta: float) -> void:
	if is_placing_body_part and is_instance_valid(part_being_placed):
		part_being_placed.global_position = creature.get_global_mouse_position()
		
	if is_drawing_connection and is_instance_valid(draw_connection_line) and is_instance_valid(last_clicked_part):
		var joint = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
		if joint:
			draw_connection_line.clear_points()
			draw_connection_line.add_point(draw_connection_line.to_local(joint.global_position))
			draw_connection_line.add_point(draw_connection_line.to_local(creature.get_global_mouse_position()))

var original_camera_pos: Vector2 = Vector2.ZERO
var original_camera_zoom: Vector2 = Vector2.ONE

func _toggle_editor_mode() -> void:
	is_editor_mode = not is_editor_mode
	
	var camera = creature.get_node_or_null("Camera2D")
	var govde = creature.get_node_or_null("Govde")
	
	if is_editor_mode:
		creature.velocity = Vector2.ZERO
		creature.change_state("edit")
		
		if camera and govde:
			original_camera_pos = camera.position
			original_camera_zoom = camera.zoom
			
		if tools_panel: tools_panel.show()
	else:
		if editor_menu: editor_menu.hide()
		if delete_menu: delete_menu.hide()
		if tools_panel: tools_panel.hide()
		if is_placing_body_part: _cancel_placing_body_part()
		creature.change_state("idle")
		
		# Kamera eski haline döndürme işi artık dynamic_camera'da
		
	_set_editor_mode_for_parts(creature, is_editor_mode)

func _set_editor_mode_for_parts(node: Node, mode: bool) -> void:
	for child in node.get_children():
		if "is_ingame_editor_active" in child:
			child.is_ingame_editor_active = mode
			if child is RigidBody2D:
				if mode:
					child.freeze = true
					var tween = create_tween().set_parallel(true)
					tween.tween_property(child, "global_position", creature.global_position + child.tpose_offset, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
					tween.tween_property(child, "global_rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				else:
					if "original_freeze" in child:
						child.freeze = child.original_freeze
		_set_editor_mode_for_parts(child, mode)

func _connect_existing_parts(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("slot_clicked"):
			if not child.slot_clicked.is_connected(_on_slot_clicked):
				child.slot_clicked.connect(_on_slot_clicked)
		if child.has_signal("body_part_right_clicked"):
			if not child.body_part_right_clicked.is_connected(_on_body_part_right_clicked):
				child.body_part_right_clicked.connect(_on_body_part_right_clicked)
		_connect_existing_parts(child)

func _on_slot_clicked(body_part: Node, slot_name: String, _button_index: int) -> void:
	last_clicked_part = body_part
	last_clicked_slot = slot_name
	
	# Sağ tıklama veya menü gösterme
	if editor_menu:
		var add_body_btn = editor_menu.get_node_or_null("VBoxContainer/Add_Body_Button")
		var connect_part_btn = editor_menu.get_node_or_null("VBoxContainer/Connect_Part_Button")
		
		var joint = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
		var is_overlapped = false
		if joint:
			var query = PhysicsShapeQueryParameters2D.new()
			var shape = CircleShape2D.new()
			shape.radius = 4.5
			query.shape = shape
			query.transform = Transform2D(0, joint.global_position)
			query.exclude = [last_clicked_part.get_rid()]
			var space_state = last_clicked_part.get_world_2d().direct_space_state
			var results = space_state.intersect_shape(query)
			is_overlapped = (results.size() > 0)
		
		# Slot doluysa ekleme işlemini kapat
		var is_occupied = last_clicked_part.has_meta("occupied_" + last_clicked_slot)
		
		if add_body_btn: add_body_btn.visible = (not is_overlapped) and (not is_occupied)
		if connect_part_btn: connect_part_btn.visible = is_overlapped and (not is_occupied)
		
		var draw_conn_btn = editor_menu.get_node_or_null("VBoxContainer/Draw_Connection_Button")
		if draw_conn_btn: draw_conn_btn.visible = not is_occupied
		
		# Menüde gösterilecek aktif bir tuş varsa menüyü aç
		if (add_body_btn and add_body_btn.visible) or (connect_part_btn and connect_part_btn.visible) or (draw_conn_btn and draw_conn_btn.visible):
			editor_menu.global_position = get_viewport().get_mouse_position()
			editor_menu.show()
		else:
			editor_menu.hide()

func _spawn_connection(part_a: Node, part_b: Node, slot_name_a: String, target_j_name: String, global_pos: Vector2) -> void:
	var conn_scene = load("res://Scenes/connection.tscn")
	var new_conn = conn_scene.instantiate()
	part_a.add_child(new_conn)
	
	new_conn.global_position = global_pos
	new_conn.node_a = new_conn.get_path_to(part_a)
	new_conn.node_b = new_conn.get_path_to(part_b)
	new_conn.slot_a = slot_name_a
	new_conn.slot_b = target_j_name
	new_conn.is_ingame_editor_active = true
	
	part_a.set_meta("occupied_" + slot_name_a, true)
	if part_a.has_method("_update_visuals"):
		part_a._update_visuals()
		
	if target_j_name != "":
		part_b.set_meta("occupied_" + target_j_name, true)
		if part_b.has_method("_update_visuals"):
			part_b._update_visuals()

func _connect_part_logic() -> void:
	editor_menu.hide()
	if not last_clicked_part or not is_instance_valid(last_clicked_part):
		return
	_connect_to_overlapping_part(last_clicked_part, last_clicked_slot)

func _connect_to_overlapping_part(part: Node, slot_name: String) -> void:
	var joint = part.get_node_or_null("Joints/" + slot_name)
	if not joint: return
	
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.5
	query.shape = shape
	query.transform = Transform2D(0, joint.global_position)
	query.exclude = [part.get_rid()]
	
	var space_state = part.get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)
	
	var target_part = null
	var closest_dist = 9999.0
	var target_j_name = ""
	
	for res in results:
		if res.collider is RigidBody2D and res.collider != part and res.collider.has_method("_get_all_joints"):
			target_part = res.collider
			break
			
	if target_part:
		var expected_local_pos = target_part.to_local(joint.global_position)
		for j_name in target_part._get_all_joints():
			var j_node = target_part.get_node_or_null("Joints/" + j_name)
			if j_node:
				var dist = j_node.position.distance_to(expected_local_pos)
				if dist < closest_dist:
					closest_dist = dist
					target_j_name = j_name
					
		if target_j_name != "":
			_spawn_connection(part, target_part, slot_name, target_j_name, joint.global_position)


func _add_body_part_logic() -> void:
	editor_menu.hide()
	
	if not last_clicked_part or not is_instance_valid(last_clicked_part):
		return
		
	if last_clicked_part.has_meta("occupied_" + last_clicked_slot):
		return # Zaten dolu, eklemeyi iptal et
				
	var body_part_scene = load("res://Scenes/body_part.tscn")
	var new_part = body_part_scene.instantiate()
	new_part.name = "BodyPart_" + str(Time.get_ticks_msec())
	
	creature.add_child(new_part)
	
	var joint = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
	if not joint: return
	
	var offset = joint.position
	var rotated_offset = offset.rotated(last_clicked_part.global_rotation)
	new_part.global_position = joint.global_position + rotated_offset
	
	new_part.tpose_offset = new_part.global_position - creature.global_position
	
	var closest_dist = 99999.0
	var closest_j = ""
	var expected_local_pos = joint.global_position - new_part.global_position
	
	for j_name in new_part._get_all_joints():
		var j_node = new_part.get_node_or_null("Joints/" + j_name)
		if j_node:
			var dist = j_node.position.distance_to(expected_local_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest_j = j_name
				
	if closest_j != "":
		new_part.global_position = joint.global_position - new_part.get_node("Joints/" + closest_j).position
		
	new_part.tpose_offset = new_part.global_position - creature.global_position
		
	new_part.slot_clicked.connect(_on_slot_clicked)
	new_part.body_part_right_clicked.connect(_on_body_part_right_clicked)
	new_part.is_ingame_editor_active = true
	new_part.freeze = true
	
	if closest_j != "":
		_spawn_connection(last_clicked_part, new_part, last_clicked_slot, closest_j, joint.global_position)
		
	await get_tree().process_frame
	is_placing_body_part = true
	part_being_placed = new_part

func _on_body_part_right_clicked(part: Node) -> void:
	if part.name == "Govde":
		return # Gövde silinemez
	
	part_to_delete = part
	delete_menu.global_position = get_viewport().get_mouse_position()
	delete_menu.show()

func _on_delete_part_pressed() -> void:
	delete_menu.hide()
	if not is_instance_valid(part_to_delete):
		return
		
	# Tüm parçaları gez, hedefi silinen parçaya bakan bağlantıları iptal et
	_clear_references_to(creature, part_to_delete)
	
	part_to_delete.queue_free()
	
	# Bir frame sonra BFS ile yetim kontrolü yap
	call_deferred("_cleanup_orphaned_parts")

func _clear_references_to(_node: Node, _target_node: Node) -> void:
	pass

func _cleanup_orphaned_parts() -> void:
	pass

func _start_placing_new_body() -> void:
	if not is_editor_mode: return
	if is_placing_body_part: return
	
	var body_part_scene = load("res://Scenes/body_part.tscn")
	part_being_placed = body_part_scene.instantiate()
	creature.add_child(part_being_placed)
	part_being_placed.is_ingame_editor_active = true
	part_being_placed.freeze = true
	part_being_placed.global_position = creature.get_global_mouse_position()
	
	if not part_being_placed.slot_clicked.is_connected(_on_slot_clicked):
		part_being_placed.slot_clicked.connect(_on_slot_clicked)
	if not part_being_placed.body_part_right_clicked.is_connected(_on_body_part_right_clicked):
		part_being_placed.body_part_right_clicked.connect(_on_body_part_right_clicked)
		
	await get_tree().process_frame
	is_placing_body_part = true

func _place_body_part() -> void:
	is_placing_body_part = false
	part_being_placed = null

func _cancel_placing_body_part() -> void:
	is_placing_body_part = false
	if is_instance_valid(part_being_placed):
		part_being_placed.queue_free()
	part_being_placed = null

func _start_drawing_connection() -> void:
	editor_menu.hide()
	if not is_instance_valid(last_clicked_part) or last_clicked_part.has_meta("occupied_" + last_clicked_slot): return
	
	draw_connection_line = Line2D.new()
	draw_connection_line.texture = load("res://Assets/Editor Assets/BaglantiSembolu.png")
	draw_connection_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	draw_connection_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	draw_connection_line.width = 30.0
	draw_connection_line.z_index = 60
	creature.add_child(draw_connection_line)
	
	await get_tree().process_frame
	is_drawing_connection = true

func _finish_drawing_connection() -> void:
	is_drawing_connection = false
	if is_instance_valid(draw_connection_line):
		draw_connection_line.queue_free()
		
	if not is_instance_valid(last_clicked_part): return
		
	var m_pos = creature.get_global_mouse_position()
	var target_part: Node = null
	var target_slot: String = ""
	var min_dist = 40.0
	
	for child in creature.get_children():
		if child is RigidBody2D and child != last_clicked_part and child.has_method("_get_all_joints"):
			for j_name in child._get_all_joints():
				if not child.has_meta("occupied_" + j_name):
					var joint = child.get_node_or_null("Joints/" + j_name)
					if joint:
						var dist = joint.global_position.distance_to(m_pos)
						if dist < min_dist:
							min_dist = dist
							target_part = child
							target_slot = j_name
							
	if target_part and target_slot != "":
		var joint_a = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
		if joint_a:
			_spawn_connection(last_clicked_part, target_part, last_clicked_slot, target_slot, joint_a.global_position)
