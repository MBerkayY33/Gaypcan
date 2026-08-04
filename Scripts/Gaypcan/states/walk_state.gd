## ===================================================================
## WalkState – Yürüme Durumu
## ===================================================================
## Canlı rastgele bir noktaya doğru yürür.
## Hedefe ulaşınca idle durumuna döner.
## ===================================================================
extends GaypcanState


## Hedef nokta
var target: Vector2 = Vector2.ZERO


func enter() -> void:
	animation_name = "walk"
	_pick_random_target()


func update(delta: float) -> void:
	# Hedefe doğru yönü hesapla
	var direction: Vector2 = (target - gaypcan.global_position).normalized()
	gaypcan.velocity = direction * gaypcan.walk_speed
	
	# Sprite yönünü güncelle
	if direction.x > 0.1:
		gaypcan.facing_right = true
	elif direction.x < -0.1:
		gaypcan.facing_right = false
	
	# Hedefe ulaştı mı?
	if gaypcan.global_position.distance_to(target) < gaypcan.arrival_threshold:
		request_transition("idle")


func exit() -> void:
	target = Vector2.ZERO


## Başlangıç pozisyonu etrafında rastgele bir hedef seçer.
func _pick_random_target() -> void:
	var angle: float = randf() * TAU
	var distance: float = randf_range(50.0, gaypcan.walk_radius)
	target = gaypcan.home_position + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)


## Dışarıdan belirli bir noktaya yönlendirmek için.
## gaypcan.gd'deki guide_towards() bunu çağırır.
func set_target(new_target: Vector2) -> void:
	target = new_target
