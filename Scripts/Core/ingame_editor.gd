extends Node
class_name IngameEditor

var is_editor_mode: bool = false
var editor_ui: CanvasLayer

var editor_menu: PanelContainer
var delete_menu: PanelContainer
var mode_label: Label
var lock_checkbox: CheckBox
var lock_color_rect: ColorRect
var is_fast_add_locked: bool = false

var last_clicked_part: Node
var last_clicked_slot: String
var part_to_delete: Node

@onready var creature: Creature = get_parent() as Creature

func _ready() -> void:
	_setup_editor_ui()
	# Bir frame bekle ki tüm body partlar hazır olsun
	call_deferred("_connect_existing_parts", creature)

func _setup_editor_ui() -> void:
	editor_ui = CanvasLayer.new()
	editor_ui.layer = 100
	add_child(editor_ui)
	
	mode_label = Label.new()
	mode_label.text = "Editör modu için \"E\" tuşuna basın"
	mode_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	mode_label.offset_left = -250
	mode_label.offset_top = -40
	mode_label.offset_right = -20
	mode_label.offset_bottom = -20
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	mode_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	mode_label.add_theme_constant_override("outline_size", 4)
	editor_ui.add_child(mode_label)
	
	editor_menu = PanelContainer.new()
	editor_menu.hide()
	editor_ui.add_child(editor_menu)
	
	var vbox = VBoxContainer.new()
	editor_menu.add_child(vbox)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var add_body_btn = Button.new()
	add_body_btn.text = " Gövde Ekle "
	add_body_btn.pressed.connect(_add_body_part_logic)
	hbox.add_child(add_body_btn)
	
	var lock_vbox = VBoxContainer.new()
	lock_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(lock_vbox)
	
	lock_color_rect = ColorRect.new()
	lock_color_rect.custom_minimum_size = Vector2(10, 10)
	lock_color_rect.color = Color.GREEN
	lock_vbox.add_child(lock_color_rect)
	
	lock_checkbox = CheckBox.new()
	lock_checkbox.toggled.connect(_on_lock_toggled)
	lock_vbox.add_child(lock_checkbox)
	
	var add_limb_btn = Button.new()
	add_limb_btn.text = " Uzuv Ekle "
	add_limb_btn.pressed.connect(func(): editor_menu.hide())
	vbox.add_child(add_limb_btn)
	
	delete_menu = PanelContainer.new()
	delete_menu.hide()
	editor_ui.add_child(delete_menu)
	
	var del_btn = Button.new()
	del_btn.text = " Sil "
	del_btn.pressed.connect(_on_delete_part_pressed)
	delete_menu.add_child(del_btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_toggle_editor_mode()
	
	if is_editor_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var m_pos = get_viewport().get_mouse_position()
		if not editor_menu.get_global_rect().has_point(m_pos):
			editor_menu.hide()
		if not delete_menu.get_global_rect().has_point(m_pos):
			delete_menu.hide()

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
			
		mode_label.hide()
	else:
		editor_menu.hide()
		delete_menu.hide()
		mode_label.show()
		creature.change_state("idle")
		
		# Kamera eski haline döndürme işi artık dynamic_camera'da
		
	_set_editor_mode_for_parts(creature, is_editor_mode)

func _set_editor_mode_for_parts(node: Node, mode: bool) -> void:
	for child in node.get_children():
		if "is_ingame_editor_active" in child:
			child.is_ingame_editor_active = mode
			if mode:
				child.freeze = true
				var tween = create_tween().set_parallel(true)
				tween.tween_property(child, "global_position", creature.global_position + child.tpose_offset, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				tween.tween_property(child, "global_rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			else:
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

func _on_slot_clicked(body_part: Node, slot_name: String, button_index: int) -> void:
	last_clicked_part = body_part
	last_clicked_slot = slot_name
	
	if is_fast_add_locked and button_index == MOUSE_BUTTON_LEFT:
		# Kilitliyse (Hızlı Ekleme) ve sol tıklandıysa menüyü açmadan direkt ekle
		_add_body_part_logic()
	else:
		# Kilitli değilse veya sağ tıklandıysa menüyü göster
		editor_menu.global_position = get_viewport().get_mouse_position()
		editor_menu.show()

func _on_lock_toggled(toggled_on: bool) -> void:
	is_fast_add_locked = toggled_on
	lock_color_rect.color = Color.RED if toggled_on else Color.GREEN
	_update_fast_add_lock_on_parts(creature)

func _update_fast_add_lock_on_parts(node: Node) -> void:
	for child in node.get_children():
		if "is_fast_add_locked" in child:
			child.is_fast_add_locked = is_fast_add_locked
			if child.has_method("queue_redraw"):
				child.queue_redraw()
		_update_fast_add_lock_on_parts(child)

func _add_body_part_logic() -> void:
	editor_menu.hide()
	
	if not last_clicked_part or not is_instance_valid(last_clicked_part):
		return
		
	var body_part_scene = load("res://Scenes/body_part.tscn")
	var new_part = body_part_scene.instantiate()
	new_part.name = "BodyPart_" + str(Time.get_ticks_msec())
	
	creature.add_child(new_part)
	
	var joint = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
	if joint:
		var a_offset = last_clicked_part.attach_offset if "attach_offset" in last_clicked_part else 35.0
		var offset = joint.position.normalized() * a_offset
		
		var rotated_offset = offset.rotated(last_clicked_part.global_rotation)
		new_part.global_position = joint.global_position + rotated_offset
		
	new_part.tpose_offset = new_part.global_position - creature.global_position
		
	new_part.slot_clicked.connect(_on_slot_clicked)
	new_part.body_part_right_clicked.connect(_on_body_part_right_clicked)
	new_part.is_ingame_editor_active = true
	new_part.freeze = true
	
	var relative_path = last_clicked_part.get_path_to(new_part)
	if "connected_parts" in last_clicked_part:
		if last_clicked_part.connected_parts == null:
			last_clicked_part.connected_parts = {}
		last_clicked_part.connected_parts[last_clicked_slot] = relative_path
		if last_clicked_part.has_method("_update_joint"):
			last_clicked_part._update_joint(last_clicked_slot, relative_path)

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

func _clear_references_to(node: Node, target_node: Node) -> void:
	for child in node.get_children():
		if child is RigidBody2D and "connected_parts" in child:
			if child.connected_parts != null:
				for j_name in child.connected_parts.keys():
					var p = child.connected_parts[j_name]
					if p and not p.is_empty():
						var n = child.get_node_or_null(p)
						if n == target_node:
							if child.has_method("_update_joint"):
								child._update_joint(j_name, NodePath(""))
		_clear_references_to(child, target_node)

func _cleanup_orphaned_parts() -> void:
	var govde: Node = null
	for child in creature.get_children():
		if child is RigidBody2D and "connected_parts" in child:
			govde = child
			break
			
	if not govde:
		return
		
	var visited = []
	var queue = [govde]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if current in visited:
			continue
			
		visited.append(current)
		
		if "connected_parts" in current and current.connected_parts != null:
			for j_name in current.connected_parts.keys():
				var path = current.connected_parts[j_name]
				if path and not path.is_empty():
					var neighbor = current.get_node_or_null(path)
					if neighbor and is_instance_valid(neighbor) and not neighbor in visited:
						queue.append(neighbor)
					
	_delete_orphans(creature, visited)

func _delete_orphans(node: Node, visited: Array) -> void:
	for child in node.get_children():
		if child is RigidBody2D and child.has_method("_update_joint"):
			if not child in visited:
				child.queue_free()
		_delete_orphans(child, visited)
