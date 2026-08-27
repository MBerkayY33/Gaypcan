extends PinJoint2D

var slot_a: String = ""
var slot_b: String = ""
@export var is_ingame_editor_active: bool = false:
	set(v):
		is_ingame_editor_active = v
		_update_visuals()

func _ready() -> void:
	_update_visuals()
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	# Node'lardan herhangi biri silindiyse veya geçerli değilse bu bağlantıyı kopar/sil
	var a = get_node_or_null(node_a)
	var b = get_node_or_null(node_b)
	if node_a.is_empty() or node_b.is_empty() or not is_instance_valid(a) or not is_instance_valid(b):
		queue_free()
		return
		
	# Zinciri uzat
	if slot_b != "":
		var target_joint = b.get_node_or_null("Joints/" + slot_b)
		if target_joint:
			var target_pos = to_local(target_joint.global_position)
			
			var shackle = get_node_or_null("Shackle") as Line2D
			if shackle:
				shackle.clear_points()
				shackle.add_point(Vector2.ZERO)
				shackle.add_point(target_pos)
				
			var body_conn = get_node_or_null("BodyConnectionPart") as Line2D
			if body_conn:
				body_conn.clear_points()
				body_conn.add_point(Vector2.ZERO)
				body_conn.add_point(target_pos)

func _update_visuals() -> void:
	var shackle = get_node_or_null("Shackle")
	if shackle:
		shackle.visible = is_ingame_editor_active

func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	var a = get_node_or_null(node_a)
	if a and slot_a != "" and a.has_meta("occupied_" + slot_a):
		a.remove_meta("occupied_" + slot_a)
		if a.has_method("_update_visuals"): a._update_visuals()
		
	var b = get_node_or_null(node_b)
	if b and slot_b != "" and b.has_meta("occupied_" + slot_b):
		b.remove_meta("occupied_" + slot_b)
		if b.has_method("_update_visuals"): b._update_visuals()

func play_animation(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
