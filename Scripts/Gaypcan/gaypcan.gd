extends CharacterBody2D
## ===================================================================
## GAYPCAN – Merkez Kontrolcü (Central Controller)
## ===================================================================
## Bu script sadece bir YÖNETİCİ. İçinde durum mantığı YOK.
##
## Görevleri:
##   1. State machine yönetimi → hangi durum aktif, geçişler
##   2. Animasyon yönetimi     → duruma göre animasyon oynatma
##   3. Dış API                → oyuncu müdahaleleri
##
## Her durum ayrı bir dosyada (Scripts/Gaypcan/states/ altında).
## Yeni bir davranış eklemek için:
##   1. GaypcanState'i extend eden yeni bir .gd dosyası yaz
##   2. Sahneye Node olarak ekle, scripti ata
##   → Bu script otomatik olarak yeni durumu tanır ve kullanır.
## ===================================================================


# =============================================
# AYARLANABILIR DEĞERLER (Inspector'dan ayarla)
# =============================================

@export_group("Hareket")
## Yürüme hızı (walk durumunda)
@export var walk_speed: float = 60.0
## Yürüme yarıçapı – canlı bu kadar uzağa kadar rastgele hedef seçer
@export var walk_radius: float = 200.0
## Hedefe bu kadar yaklaşınca "vardım" sayılır
@export var arrival_threshold: float = 10.0

@export_group("Zamanlayıcılar")
## IDLE durumunda minimum bekleme süresi (saniye)
@export var idle_min_time: float = 1.5
## IDLE durumunda maksimum bekleme süresi (saniye)
@export var idle_max_time: float = 4.0

@export_group("Başlangıç Durumu")
## Sahne açıldığında hangi durumla başlar (node adı, küçük harf)
@export var initial_state_name: String = "idle"


# =============================================
# İÇ DEĞİŞKENLER
# =============================================

## Sprite yönü
var facing_right: bool = true

## Başlangıç pozisyonu (walk merkezi)
var home_position: Vector2 = Vector2.ZERO


# =============================================
# STATE MACHINE DEĞİŞKENLERİ
# =============================================

## Kayıtlı tüm durumlar: { "idle": IdleState, "walk": WalkState }
var states: Dictionary = {}
## Şu an aktif olan durum
var current_state: GaypcanState = null
## Bir önceki durum (debug ve geçiş kontrolü için)
var previous_state: GaypcanState = null


# =============================================
# NODE REFERANSLARI
# =============================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_tree: AnimationTree = $AnimationTree

var anim_state_machine: AnimationNodeStateMachinePlayback = null
var use_anim_tree: bool = false


# =============================================
# HAZIRLIK (Ready)
# =============================================

func _ready() -> void:
	home_position = global_position
	
	# --- State'leri Otomatik Keşfet ---
	# Sahne ağacındaki tüm GaypcanState çocuklarını bul ve kaydet.
	# Node adı küçük harfe çevrilerek anahtar olarak kullanılır.
	for child in get_children():
		if child is GaypcanState:
			var state_name: String = child.name.to_lower()
			states[state_name] = child
			child.gaypcan = self
			child.transition_requested.connect(_on_transition_requested)
			print("[Gaypcan] Durum bulundu: '%s'" % state_name)
	
	# --- AnimationTree Kontrolü ---
	if anim_tree and anim_tree.tree_root:
		anim_tree.active = true
		anim_state_machine = anim_tree.get("parameters/playback")
		use_anim_tree = true
		print("[Gaypcan] AnimationTree aktif")
	else:
		use_anim_tree = false
		print("[Gaypcan] AnimatedSprite2D modu (AnimationTree yapılandırılmamış)")
	
	# --- Başlangıç Durumunu Ayarla ---
	if states.has(initial_state_name):
		current_state = states[initial_state_name]
		current_state.enter()
		print("[Gaypcan] Başlangıç durumu: '%s'" % initial_state_name)
	else:
		push_error("[Gaypcan] Başlangıç durumu '%s' bulunamadı! Mevcut durumlar: %s" % [
			initial_state_name, states.keys()
		])


# =============================================
# ANA DÖNGÜ
# =============================================

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)  # 1. Aktif durumun mantığını çalıştır
	
	_update_animation()              # 2. Animasyonu güncelle
	move_and_slide()                 # 3. Fizik hareketini uygula


# =============================================
# STATE MACHINE – GEÇİŞ YÖNETİMİ
# =============================================

## Bir durumdan diğerine geçiş yapar.
## Eski durumun exit()'ini, yeni durumun enter()'ını çağırır.
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_warning("[Gaypcan] Durum bulunamadı: '%s'" % new_state_name)
		return
	
	var new_state: GaypcanState = states[new_state_name]
	
	# Aynı duruma tekrar girmeyi engelle
	if new_state == current_state:
		return
	
	# Geçiş yap
	var old_name: String = current_state.name if current_state else "YOK"
	
	if current_state:
		current_state.exit()
	
	previous_state = current_state
	current_state = new_state
	current_state.enter()
	
	print("[Gaypcan] %s → %s" % [old_name, current_state.name])


func _on_transition_requested(new_state_name: String) -> void:
	change_state(new_state_name)


# =============================================
# ANİMASYON YÖNETİMİ
# =============================================

func _update_animation() -> void:
	if not current_state:
		return
	
	# Sprite yön çevirme
	if animated_sprite:
		animated_sprite.flip_h = not facing_right
	
	# Duruma göre animasyon oynat
	var anim_name: String = current_state.animation_name
	
	if use_anim_tree and anim_state_machine:
		# AnimationTree modu
		anim_state_machine.travel(anim_name)
	elif animated_sprite:
		# AnimatedSprite2D modu
		if animated_sprite.animation != anim_name:
			if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
				animated_sprite.play(anim_name)


# =============================================
# DIŞ ETKİLEŞİM API'Sİ
# =============================================

## Canlıyı belirli bir noktaya yönlendirir.
func guide_towards(target: Vector2) -> void:
	var walk_state = states.get("walk")
	if walk_state and walk_state.has_method("set_target"):
		walk_state.set_target(target)
	if current_state == states.get("idle") or current_state == states.get("walk"):
		change_state("walk")
