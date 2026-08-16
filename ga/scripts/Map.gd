class_name Map extends RefCounted

const Width := 256
const Height := 256

const YAYILIM_HIZI := 2


const VERIM_ESIK := 0.3
const VERIM_ARTIS := 0.05
const VERIM_AZALIS := 0.02


var nem:       PackedFloat32Array
var nem_update:PackedFloat32Array
var gunes:     PackedFloat32Array
var verim:     PackedFloat32Array



func _init() -> void:
	var n = Width * Height
	nem.resize(n)
	gunes.resize(n)
	verim.resize(n)
	nem_update.resize(n)

	
var img = Image.create(Width,Height,false,Image.FORMAT_RGB8)	



func produce_ground():
	pass
	
	
func verim_guncelleme(dt: float) -> void:
	for i in verim.size():
		if nem[i] > VERIM_ESIK:
			verim[i] += VERIM_ARTIS * (nem[i] - VERIM_ESIK) / (1.0 - VERIM_ESIK) * dt
		elif nem[i] < VERIM_ESIK:
			verim[i] -= VERIM_AZALIS * (VERIM_ESIK - nem[i]) / VERIM_ESIK * dt
		verim[i] = clampf(verim[i], 0.0, 1.0)
		
func yayilim_fonksiyonu(dt: float) -> void:
	nem_update.fill(0.0)
	var water_out_coef = min(YAYILIM_HIZI*dt,0.2)
	for y in Height:
		for x in Width:
			var i := y*Width+x
			var water_out = nem[i] *water_out_coef
			var count := 0
			
			if x > 0:				
				nem_update[i - 1] += water_out
				count +=1
			if x < Width - 1:
				nem_update[i + 1] += water_out
				count +=1
			if y > 0:
				nem_update[i - Width] += water_out
				count +=1
			if y < Height - 1:
				nem_update[i + Width] += water_out
				count +=1
			nem_update[i] -= count*water_out
			
	for j in nem.size():
		nem[j] += nem_update[j]
