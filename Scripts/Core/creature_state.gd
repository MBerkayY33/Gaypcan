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

## Duruma girildiğinde 1 kez çağrılır.
func enter() -> void:
	pass

## Her fizik karesinde çağrılır (~60 FPS).
func update(delta: float) -> void:
	pass

## Durumdan çıkılırken 1 kez çağrılır.
func exit() -> void:
	pass

# =============================================
# YARDIMCI FONKSİYONLAR
# =============================================

## Başka bir duruma geçiş talep eder.
func request_transition(state_name: String) -> void:
	transition_requested.emit(state_name)
