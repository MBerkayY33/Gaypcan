## ===================================================================
## GaypcanState – Temel Durum Sınıfı (Base State)
## ===================================================================
## Tüm durumlar (Idle, Wander, Eat, Sleep, Flee...) bu sınıftan türer.
## Yeni bir davranış eklemek istersen:
##   1. Bu sınıfı extend eden yeni bir .gd dosyası oluştur
##   2. enter(), update(), exit() fonksiyonlarını override et
##   3. Sahneye yeni bir Node olarak ekle, scripti ata
##   → Gaypcan otomatik olarak bu yeni durumu tanır ve kullanır.
##
## KULLANIM:
##   - gaypcan değişkeni üzerinden ana karaktere erişirsin
##   - request_transition("durum_adi") ile durum geçişi talep edersin
##   - animation_name değişkenini set ederek animasyonu belirlersin
## ===================================================================
class_name GaypcanState
extends Node

var gaypcan: CharacterBody2D = null
var animation_name: String = "idle"
signal transition_requested(new_state_name: String)

func enter() -> void:
	pass

func update(delta: float) -> void:
	pass

func exit() -> void:
	pass

func request_transition(state_name: String) -> void:
	transition_requested.emit(state_name)
