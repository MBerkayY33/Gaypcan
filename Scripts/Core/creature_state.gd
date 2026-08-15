class_name CreatureState
extends Node

## Sahip olunan canlı referansı.
var creature = null
## Bu durumda oynatılacak animasyonun adı.
var animation_name: String = "idle"
## Durum geçişi talep sinyali.
signal transition_requested(new_state_name: String)

# =============================================
# TEMEL FONKSİYONLAR (Override edilecekler)
# =============================================

func enter() -> void:
	pass
	
func update(delta: float) -> void:
	pass

func exit() -> void:
	pass

# =============================================
# YARDIMCI FONKSİYONLAR
# =============================================

## Başka bir duruma geçiş talep eder.
func request_transition(state_name: String) -> void:
	transition_requested.emit(state_name)
