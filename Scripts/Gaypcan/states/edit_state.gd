## ===================================================================
## EditState – Düzenleme Durumu
## ===================================================================
extends CreatureState

func enter() -> void:
	animation_name = "edit"
	creature.velocity = Vector2.ZERO

func update(delta: float) -> void:
	# Sadece sürtünme ile durmayı garantile
	creature.velocity = creature.velocity.move_toward(Vector2.ZERO, creature.friction * delta)

func exit() -> void:
	pass
