## ===================================================================
## IdleState – Bekleme Durumu
## ===================================================================
## Canlı bir yerde durur, etrafına bakar.
## Belirli bir süre sonra yürümeye (walk) geçer.
## ===================================================================
extends GaypcanState

## Bekleme süre sayacı
var timer: float = 0.0

func enter() -> void:
	animation_name = "idle"
	gaypcan.velocity = Vector2.ZERO
	
	# Rastgele bir süre bekle
	timer = randf_range(gaypcan.idle_min_time, gaypcan.idle_max_time)

func update(delta: float) -> void:
	gaypcan.velocity = Vector2.ZERO
	
	# Süre dolunca yürümeye başla
	timer -= delta
	if timer <= 0.0:
		request_transition("walk")

func exit() -> void:
	timer = 0.0
