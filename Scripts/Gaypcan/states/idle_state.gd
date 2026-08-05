## ===================================================================
## IdleState – Bekleme Durumu
## ===================================================================
extends CreatureState

## Bekleme süre sayacı
var timer: float = 0.0

func enter() -> void:
	animation_name = "idle"
	creature.velocity = Vector2.ZERO
	
	# Rastgele bir süre bekle
	timer = randf_range(creature.idle_min_time, creature.idle_max_time)

func update(delta: float) -> void:
	# Sürtünme ile yumuşak bir şekilde dur
	creature.velocity = creature.velocity.move_toward(Vector2.ZERO, creature.friction * delta)
	
	# Süre dolunca yürümeye başla
	timer -= delta
	if timer <= 0.0:
		request_transition("walk")

func exit() -> void:
	timer = 0.0
