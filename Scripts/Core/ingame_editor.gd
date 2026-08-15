extends Node
class_name IngameEditor

var is_editor_mode: bool = false
var editor_ui: CanvasLayer
var add_part_btn: Button

var last_clicked_part: Node
var last_clicked_slot: String

@onready var creature: Creature = get_parent() as Creature

func _ready() -> void:
	_setup_editor_ui()
	# Bir frame bekle ki tüm body partlar hazır olsun
	call_deferred("_connect_existing_parts", creature)

func _setup_editor_ui() -> void:
	editor_ui = CanvasLayer.new()
	editor_ui.layer = 100
	add_child(editor_ui)
	
	add_part_btn = Button.new()
	add_part_btn.text = " Parça Ekle "
	add_part_btn.hide()
	add_part_btn.pressed.connect(_on_add_part_pressed)
	editor_ui.add_child(add_part_btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_toggle_editor_mode()
	
	if is_editor_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var m_pos = get_viewport().get_mouse_position()
		if not add_part_btn.get_global_rect().has_point(m_pos):
			add_part_btn.hide()

var original_camera_pos: Vector2 = Vector2.ZERO
var original_camera_zoom: Vector2 = Vector2.ONE

func _toggle_editor_mode() -> void:
	is_editor_mode = not is_editor_mode
	
	var camera = creature.get_node_or_null("Camera2D")
	var govde = creature.get_node_or_null("Govde")
	
	if is_editor_mode:
		creature.velocity = Vector2.ZERO
		creature.change_state("idle")
		
		# Kamerayı gövdeye odakla ve yakınlaş
		if camera and govde:
			original_camera_pos = camera.position
			original_camera_zoom = camera.zoom
			
			var tween = create_tween().set_parallel(true)
			tween.tween_property(camera, "position", govde.position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		add_part_btn.hide()
		
		# Kamerayı eski haline döndür
		if camera:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(camera, "position", original_camera_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(camera, "zoom", original_camera_zoom, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
	_set_editor_mode_for_parts(creature, is_editor_mode)

func _set_editor_mode_for_parts(node: Node, mode: bool) -> void:
	for child in node.get_children():
		if "is_ingame_editor_active" in child:
			child.is_ingame_editor_active = mode
		_set_editor_mode_for_parts(child, mode)

func _connect_existing_parts(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("slot_clicked"):
			if not child.slot_clicked.is_connected(_on_slot_clicked):
				child.slot_clicked.connect(_on_slot_clicked)
		_connect_existing_parts(child)

func _on_slot_clicked(body_part: Node, slot_name: String) -> void:
	last_clicked_part = body_part
	last_clicked_slot = slot_name
	
	add_part_btn.global_position = get_viewport().get_mouse_position()
	add_part_btn.show()

func _on_add_part_pressed() -> void:
	add_part_btn.hide()
	
	if not last_clicked_part or not is_instance_valid(last_clicked_part):
		return
		
	var body_part_scene = load("res://Scenes/body_part.tscn")
	var new_part = body_part_scene.instantiate()
	new_part.name = "BodyPart_" + str(Time.get_ticks_msec())
	
	creature.add_child(new_part)
	
	var joint = last_clicked_part.get_node_or_null("Joints/" + last_clicked_slot)
	if joint:
		var offset = Vector2.ZERO
		if last_clicked_slot.begins_with("Top"): offset = Vector2(0, -35)
		elif last_clicked_slot.begins_with("Bottom"): offset = Vector2(0, 35)
		elif last_clicked_slot.begins_with("Left"): offset = Vector2(-35, 0)
		elif last_clicked_slot.begins_with("Right"): offset = Vector2(35, 0)
		
		var rotated_offset = offset.rotated(last_clicked_part.global_rotation)
		new_part.global_position = joint.global_position + rotated_offset
		
	new_part.slot_clicked.connect(_on_slot_clicked)
	new_part.is_ingame_editor_active = true
	
	var relative_path = last_clicked_part.get_path_to(new_part)
	last_clicked_part.set(last_clicked_slot.to_lower(), relative_path)
