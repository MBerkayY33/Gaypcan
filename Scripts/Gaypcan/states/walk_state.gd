## ===================================================================
## WalkState – Yürüme Durumu
## ===================================================================
extends CreatureState

## Hedef nokta
var target: Vector2 = Vector2.ZERO


func enter() -> void:
	animation_name = "walk"
	_pick_random_target()


func update(delta: float) -> void:
	# Hedefe doğru yönü hesapla
	var direction: Vector2 = (target - creature.global_position).normalized()
	
	# Hızı yumuşak bir şekilde artır (İvme kullanımı)
	var desired_velocity: Vector2 = direction * creature.walk_speed
	creature.velocity = creature.velocity.move_toward(desired_velocity, creature.acceleration * delta)
	
	# Sprite yönünü güncelle
	if creature.velocity.x > 0.1:
		creature.facing_right = true
	elif creature.velocity.x < -0.1:
		creature.facing_right = false
	
	# Hedefe ulaştı mı?
	if creature.global_position.distance_to(target) < creature.arrival_threshold:
		request_transition("idle")


func exit() -> void:
	target = Vector2.ZERO


## Başlangıç pozisyonu etrafında rastgele bir hedef seçer.
func _pick_random_target() -> void:
	var angle: float = randf() * TAU
	var distance: float = randf_range(50.0, creature.walk_radius)
	target = creature.home_position + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)


## Dışarıdan belirli bir noktaya yönlendirmek için.
func set_target(new_target: Vector2) -> void:
	target = new_target
