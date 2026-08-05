class_name Creature
extends CharacterBody2D

# =============================================
# GENEL DEĞİŞKENLER
# =============================================
## Sprite yönü (true = sağa bakıyor)
var facing_right: bool = true
## Başlangıç pozisyonu (spawn noktası)
var home_position: Vector2 = Vector2.ZERO

# =============================================
# STATE MACHINE DEĞİŞKENLERİ
# =============================================
## Kayıtlı tüm durumlar
var states: Dictionary = {}
## Şu an aktif olan durum
var current_state: CreatureState = null
## Bir önceki durum
var previous_state: CreatureState = null

# =============================================
# ANİMASYON DEĞİŞKENLERİ
# =============================================
## Sprite node referansı (Sprite2D veya AnimatedSprite2D – _ready'de bulunur)
var sprite_node = null
@onready var anim_tree: AnimationTree = $AnimationTree
var anim_state_machine: AnimationNodeStateMachinePlayback = null
var use_anim_tree: bool = false


# =============================================
# AYARLANABILIR DEĞERLER
# =============================================

@export_group("Hareket")
## Yürüme hızı
@export var walk_speed: float = 60.0
## Hızlanma ivmesi (Yumuşak hareket için)
@export var acceleration: float = 300.0
## Yavaşlama sürtünmesi (Yumuşak duruş için)
@export var friction: float = 300.0
## Yürüme/dolaşma yarıçapı
@export var walk_radius: float = 200.0
## Hedefe varış eşiği
@export var arrival_threshold: float = 10.0

@export_group("Zamanlayıcılar")
## IDLE minimum bekleme süresi (saniye)
@export var idle_min_time: float = 1.5
## IDLE maksimum bekleme süresi (saniye)
@export var idle_max_time: float = 4.0

@export_group("Başlangıç Durumu")
## Sahne açıldığında hangi durumla başlar (node adı, küçük harf)
@export var initial_state_name: String = "idle"


# =============================================
# START
# =============================================

func _ready() -> void:
	home_position = global_position
	_find_sprite_node()
	_discover_states()
	_setup_animation_tree()
	_set_initial_state()


## Sahne ağacında Sprite2D veya AnimatedSprite2D bulur.
func _find_sprite_node() -> void:
	if has_node("AnimatedSprite2D"):
		sprite_node = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		sprite_node = $Sprite2D


## Sahne ağacındaki tüm CreatureState çocuklarını bulur ve kaydeder.
func _discover_states() -> void:
	for child in get_children():
		if child is CreatureState:
			var state_name: String = child.name.to_lower()
			states[state_name] = child
			child.creature = self
			child.transition_requested.connect(_on_transition_requested)
			_log("Durum bulundu: '%s'" % state_name)


## AnimationTree yapılandırılmışsa aktif eder.
func _setup_animation_tree() -> void:
	if anim_tree and anim_tree.tree_root:
		anim_tree.active = true
		anim_state_machine = anim_tree.get("parameters/playback")
		use_anim_tree = true
		_log("AnimationTree aktif")
	else:
		use_anim_tree = false
		_log("AnimatedSprite2D modu (AnimationTree yapılandırılmamış)")


## Başlangıç durumunu ayarlar.
func _set_initial_state() -> void:
	if states.has(initial_state_name):
		current_state = states[initial_state_name]
		current_state.enter()
		_log("Başlangıç durumu: '%s'" % initial_state_name)
	else:
		push_error("[%s] Başlangıç durumu '%s' bulunamadı! Mevcut: %s" % [
			_get_creature_name(), initial_state_name, states.keys()
		])


# =============================================
# UPDATE
# =============================================

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

	_update_animation()
	move_and_slide()


# =============================================
# STATE MACHINE – GEÇİŞ YÖNETİMİ
# =============================================

## Bir durumdan diğerine geçiş yapar.
func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_warning("[%s] Durum bulunamadı: '%s'" % [_get_creature_name(), new_state_name])
		return

	var new_state: CreatureState = states[new_state_name]

	if new_state == current_state:
		return

	var old_name: String = current_state.name if current_state else "YOK"

	if current_state:
		current_state.exit()

	previous_state = current_state
	current_state = new_state
	current_state.enter()

	_log("%s → %s" % [old_name, current_state.name])


## State'lerden gelen geçiş taleplerini dinler.
func _on_transition_requested(new_state_name: String) -> void:
	change_state(new_state_name)


# =============================================
# ANİMASYON YÖNETİMİ
# =============================================

func _update_animation() -> void:
	if not current_state:
		return

	# Sprite yön çevirme (hem Sprite2D hem AnimatedSprite2D'de çalışır)
	if sprite_node:
		sprite_node.flip_h = not facing_right

	var anim_name: String = current_state.animation_name

	if use_anim_tree and anim_state_machine:
		# AnimationTree modu – travel() ile geçiş
		anim_state_machine.travel(anim_name)
	elif sprite_node is AnimatedSprite2D:
		# Fallback: AnimatedSprite2D doğrudan oynatma
		if sprite_node.animation != anim_name:
			if sprite_node.sprite_frames and sprite_node.sprite_frames.has_animation(anim_name):
				sprite_node.play(anim_name)


# =============================================
# ALT SINIFLAR İÇİN
# =============================================

## Canlının adını döndürür. Alt sınıflar override etmelidir.
func _get_creature_name() -> String:
	return "Creature"


## Konsola formatlı log yazar.
func _log(message: String) -> void:
	print("[%s] %s" % [_get_creature_name(), message])
