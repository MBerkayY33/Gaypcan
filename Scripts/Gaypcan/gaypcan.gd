class_name Gaypcan
extends Creature

# =============================================
# VARSAYILAN DEĞER ÖZELLEŞTİRMELERİ
# =============================================
func _init() -> void:
	walk_speed = 60.0
	acceleration = 250.0
	friction = 350.0
	walk_radius = 200.0
	arrival_threshold = 10.0
	idle_min_time = 1.5
	idle_max_time = 4.0

# =============================================
# GAYPCAN – KİMLİK
# =============================================
func _get_creature_name() -> String:
	return "Gaypcan"
	
# =============================================
# GAYPCAN – DİĞER FONKSİYONLAR
# =============================================

## Gaypcan'ı belirli bir noktaya yönlendirir.
func guide_towards(target: Vector2) -> void:
	var walk_state = states.get("walk")
	if walk_state and walk_state.has_method("set_target"):
		walk_state.set_target(target)
	if current_state == states.get("idle") or current_state == states.get("walk"):
		change_state("walk")
