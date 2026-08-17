@tool
extends RigidBody2D

## Modüler Vücut Parçası — Sınırsız Bağlantı Noktalı Fiziksel Parça
## 'Joints' node'unun altındaki tüm PinJoint2D'ler otomatik olarak algılanır.

# ==========================================
# SİNYALLER VE DEĞİŞKENLER
# ==========================================

signal slot_clicked(body_part: Node, slot_name: String, button_index: int) # Bir bağlantı noktasına tıklandığında tetiklenir
signal body_part_right_clicked(part: Node) # Parçanın kendisine sağ tıklandığında (silmek için) tetiklenir

@export var spring_torque: float = 4000.0 # Parçanın sallanırken kendi orijinal açısına (T-Pose) dönme gücü
@export var connected_parts: Dictionary = {} # Hangi bağlantı noktasına hangi hedefin bağlandığını saklayan Sözlük (Örn: "Joint_1": NodePath)

## connected_parts Sözlüğünün güvenli (Nil olmayan) halini döndürür.
func _get_connected_parts() -> Dictionary:
	if connected_parts == null:
		connected_parts = {}
	return connected_parts

@export var is_ingame_editor_active: bool = false:
	set(v):
		is_ingame_editor_active = v
		queue_redraw() # Editör modu açılıp kapandığında ekranda noktaları yeniden çizmek için
		
@export var hover_radius: float = 5.0 # Oyun içinde bağlantıların üst üste binip binmediğini (çakışma) tespit etme yarıçapı
@export var mouse_detect_radius: float = 20.0 # Farenin bağlantı noktasını algılama mesafesi (128x128 sprite için 20 idealdir)
@export var attach_offset: float = 35.0 # Yeni bağlanan parçanın merkezden ne kadar uzağa (dışarı) itileceği (128x128 için genelde 35'tir)

var tpose_offset: Vector2 = Vector2.ZERO # Başlangıçtaki lokal pozisyon (T-Pose durumu)
var original_freeze: bool = false # Başlangıçtaki dondurulma (freeze) durumunu hafızada tutar
var hovered_joint: String = "" # Farenin o an üzerinde olduğu bağlantı noktasının adı
var is_fast_add_locked: bool = false # Seri tıklamayla menü açmadan parça ekleme kilit modu (Asma Kilit sembolü)
var overlapped_joints: Array[String] = [] # Fiziksel olarak başka bir parçanın içinde kalan bağlantı noktalarının listesi

# ==========================================
# BAŞLATMA VE BAĞLANTI (JOINT) YÖNETİMİ
# ==========================================

## 'Joints' düğümü altındaki tüm PinJoint2D düğümlerinin isimlerini (Örn: Joint_1, Joint_2) dinamik olarak döndürür
func _get_all_joints() -> Array[String]:
	var list: Array[String] = []
	var joints_node = get_node_or_null("Joints")
	if joints_node:
		for child in joints_node.get_children():
			if child is PinJoint2D:
				list.append(child.name)
	return list

## Oyun başlarken veya sahne yüklenirken ilk hazırlıklar
func _ready() -> void:
	tpose_offset = position
	original_freeze = freeze
	
	# Eğer oyun çalışıyorsa ve parça hareketli bir uzuv ise (dondurulmamışsa)
	if not Engine.is_editor_hint():
		if not freeze:
			var g_pos = global_position
			var g_rot = global_rotation
			top_level = true # Ebeveynin hareketini kopyalama, tamamen fizikle sürüklen!
			global_position = g_pos
			global_rotation = g_rot
			can_sleep = false # Hareketsiz kaldığında uyku moduna geçip donmasını engeller
			
	# Tüm node'lar sahneye eklendikten sonra (1 frame bekler) fiziksel bağlantıları kur
	call_deferred("_apply_all_joints")

## Sözlükte (Dictionary) kayıtlı olan tüm bağlantı yollarını fizik motoruna (PinJoint2D'lere) uygular
func _apply_all_joints() -> void:
	var dict = _get_connected_parts()
	for j_name in dict.keys():
		_update_joint(j_name, dict[j_name])

## Tek bir PinJoint2D'nin 'node_b' hedefini günceller ve Sözlüğe kaydeder
func _update_joint(joint_name: String, target_path: NodePath) -> void:
	if not is_inside_tree():
		return
		
	var dict = _get_connected_parts()

	var joint = get_node_or_null("Joints/" + joint_name)
	if not joint or not joint is PinJoint2D:
		return

	# Hedef boşsa bağlantıyı kopar ve sözlükten sil
	if target_path.is_empty():
		joint.node_b = NodePath("")
		dict.erase(joint_name)
		return

	var target = get_node_or_null(target_path)
	if not target:
		return

	# Aynı parçanın başka noktalara (Duplicate) bağlanmasını engelle
	_clear_duplicates(joint_name, target_path)

	dict[joint_name] = target_path
	joint.node_b = joint.get_path_to(target) # PinJoint2D'nin beklediği göreceli (relative) yol

## Bir parça zaten başka bir slota takılıysa, o eski slotu temizler (Bir kol 2 ayrı omuza takılamaz)
func _clear_duplicates(current_joint: String, target_path: NodePath) -> void:
	if target_path.is_empty():
		return
		
	var dict = _get_connected_parts()
		
	for j_name in _get_all_joints():
		if j_name == current_joint:
			continue
		if dict.get(j_name, NodePath()) == target_path:
			dict.erase(j_name)
			var old_joint = get_node_or_null("Joints/" + j_name)
			if old_joint and old_joint is PinJoint2D:
				old_joint.node_b = NodePath("")

# ==========================================
# ÇAKIŞMA KONTROLÜ VE EKRANA ÇİZİM
# ==========================================

## Her fizik karesinde (frame) çakışan (başka parçanın içinde kalan) noktaları tespit eder
func _physics_process(delta: float) -> void:
	if not is_ingame_editor_active:
		return
		
	overlapped_joints.clear()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = hover_radius # Yarıçap Inspector'dan ayarlanır
	query.shape = shape
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self.get_rid()] # Kendi gövdesini aramadan dışla
	
	var dict = _get_connected_parts()
	for j_name in _get_all_joints():
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint: continue
		
		var target_path = dict.get(j_name, NodePath())
		var is_connected = not target_path.is_empty()
		if is_connected: continue # Zaten bağlıysa çakışma testine gerek yok
		
		# O noktada fiziksel bir obje var mı diye daire şeklinde tarama yap
		query.transform = Transform2D(0, joint.global_position)
		var results = space_state.intersect_shape(query)
		if results.size() > 0:
			overlapped_joints.append(j_name)
	
	queue_redraw() # _draw() fonksiyonunu tetikleyerek ekranı yenile

## Oyun içi editör açıkken bağlantı noktalarını (beyaz/kırmızı yuvarlak ve yeşil artı) çizer
func _draw() -> void:
	if not is_ingame_editor_active:
		return
		
	var dict = _get_connected_parts()
	for j_name in _get_all_joints():
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint:
			continue
			
		var target_path = dict.get(j_name, NodePath())
		var is_connected = not target_path.is_empty()
		
		var color = Color.RED if is_connected else Color.WHITE
		
		if not is_connected and j_name in overlapped_joints:
			# Çakışan noktalara kırmızı çarpı (X) çiz
			var p = joint.position
			draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), Color.RED, 2.0)
			draw_line(p + Vector2(4, -4), p + Vector2(-4, 4), Color.RED, 2.0)
		else:
			# Normal durumlarda beyaz veya kırmızı daire çiz
			draw_circle(joint.position, 4.5, color)
			
			if j_name == hovered_joint:
				# Fare üstündeyse yeşil artı (+) çiz
				var p = joint.position
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), Color.GREEN, 1.5)
				draw_line(p + Vector2(0, -3), p + Vector2(0, 3), Color.GREEN, 1.5)
				
				if is_fast_add_locked:
					# Hızlı ekleme kilidi aktifse ufak bir kırmızı asma kilit çiz
					var lock_pos = p + Vector2(6, -6)
					draw_rect(Rect2(lock_pos, Vector2(5, 4)), Color.RED, true)
					draw_arc(lock_pos + Vector2(2.5, 0), 2.0, PI, TAU, 10, Color.RED, 1.0)

# ==========================================
# FARE ETKİLEŞİMLERİ (INPUT)
# ==========================================

## Fare ile noktaların üzerine gelme ve noktalara tıklama durumlarını yönetir
func _unhandled_input(event: InputEvent) -> void:
	if not is_ingame_editor_active:
		return
		
	# Fare hareketi: Hangi noktanın üzerinde olduğumuzu hesapla
	if event is InputEventMouseMotion:
		var local_mouse = get_local_mouse_position()
		var found_hover = ""
		var min_dist = mouse_detect_radius # En fazla bu kadar uzaktayken algılar
		var dict = _get_connected_parts()
		for j_name in _get_all_joints():
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			var dist = local_mouse.distance_to(joint.position)
			if dist <= min_dist:
				var target_path = dict.get(j_name, NodePath())
				var is_connected = not target_path.is_empty()
				if not is_connected and not (j_name in overlapped_joints):
					found_hover = j_name
					min_dist = dist # Daha yakın bir tane bulduk, mesafe sınırını buna çek
					
		if hovered_joint != found_hover:
			hovered_joint = found_hover
			queue_redraw() # Eski fare konumu silinsin, yeni yeşil artı çizilsin diye
			
	# Fare Tıklaması: Bir noktaya tıklandığında ekleme işlemlerini başlat (slot_clicked sinyali)
	if event is InputEventMouseButton and event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
		var local_mouse = get_local_mouse_position()
		var dict = _get_connected_parts()
		
		var clicked_j_name = ""
		var min_dist = mouse_detect_radius
		for j_name in _get_all_joints():
			var joint = get_node_or_null("Joints/" + j_name)
			if not joint: continue
			
			var dist = local_mouse.distance_to(joint.position)
			if dist <= min_dist:
				var target_path = dict.get(j_name, NodePath())
				var is_connected = not target_path.is_empty()
				if not is_connected:
					clicked_j_name = j_name
					min_dist = dist
					
		if clicked_j_name != "":
			if clicked_j_name in overlapped_joints:
				get_viewport().set_input_as_handled()
				return
			slot_clicked.emit(self, clicked_j_name, event.button_index)
			get_viewport().set_input_as_handled()
			return

## Parçanın kendisine sağ tıklandığını algılar (Silme menüsü için)
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not is_ingame_editor_active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		body_part_right_clicked.emit(self)
		get_viewport().set_input_as_handled()

# ==========================================
# EDİTÖR İÇİ HİZALAMA VE ANİMASYON
# ==========================================

## Normal her frame döngüsü. Editördeysek hizalama yapar, oyundaysak görselleri (artı sembolü) günceller.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_snap_all_attached_parts()
	else:
		_update_visuals()

## Sprite olarak eklenen "Con_Point" ve "Plus" nesnelerinin görünürlüğünü ayarlar
func _update_visuals() -> void:
	# Oyun içi editör açık değilse tamamen gizle
	if not is_ingame_editor_active:
		for j_name in _get_all_joints():
			var con_point = get_node_or_null("Joints/" + j_name + "/Con_Point")
			if con_point: con_point.visible = false
			var plus = get_node_or_null("Joints/" + j_name + "/Plus")
			if plus: plus.visible = false
		return
		
	var dict = _get_connected_parts()	
	for j_name in _get_all_joints():
		var joint = get_node_or_null("Joints/" + j_name)
		if not joint: continue
		
		var target_path = dict.get(j_name, NodePath())
		var is_connected = not target_path.is_empty()
		
		var con_point = get_node_or_null("Joints/" + j_name + "/Con_Point")
		var plus = get_node_or_null("Joints/" + j_name + "/Plus")
		
		# Sadece boş olan ve üst üste binmemiş (çakışmamış) noktalarda beyaz daireyi göster
		if not is_connected and not (j_name in overlapped_joints):
			if con_point: con_point.visible = true
			if plus: plus.visible = (j_name == hovered_joint) # Farenin üstünde olduğu noktada yeşil artıyı yak
		else:
			if con_point: con_point.visible = false
			if plus: plus.visible = false

## Editörde Inspector üzerinden bağlanan parçaları otomatik olarak dışarı iter ve uç uca hizalar
func _snap_all_attached_parts() -> void:
	var dict = _get_connected_parts()
	for j_name in _get_all_joints():
		var target_path = dict.get(j_name, NodePath())
		if not target_path.is_empty():
			var target = get_node_or_null(target_path)
			var joint = get_node_or_null("Joints/" + j_name)
			if target and target is Node2D and joint:
				# Noktanın merkezden hangi yöne doğru (normali) baktığını bul ve o yönde it
				# Bu sayede isimlerden (Top, Bottom) bağımsız, 360 derece her yöne dinamik yapışma sağlanır.
				var offset = joint.position.normalized() * attach_offset
				
				# Vücudun rotasyonunu (dönüşünü) hesaba katarak itme vektörünü çevir
				var rotated_offset = offset.rotated(global_rotation)
				target.global_position = joint.global_position + rotated_offset

## Fizik motorunun özel entegrasyonu (Yay etkisi yaratır)
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if Engine.is_editor_hint():
		return
	if freeze:
		return
		
	# Uzuvların hareket ederken hafifçe sallanıp sonra orijinal açılarına dönmesini (yaylanmasını) sağlar
	var target_rotation = 0.0
	var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
	
	state.apply_torque(angle_diff * spring_torque) # Dönüş açısına doğru güç uygula
	state.angular_velocity *= 0.90 # Sürekli dönmesini engellemek (sönümlemek) için yavaşlat

## Yürüme vb. animasyonları tetikleyen yardımcı fonksiyon
func play_animation(anim_name: String) -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
