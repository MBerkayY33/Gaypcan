class_name Map extends RefCounted

const Width := 256
const Height := 256

const YAYILIM_HIZI := 2



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
	
func yayilim_fonksiyonu(dt: float) -> void:
	var water_out_coef = min(YAYILIM_HIZI*dt,0.2)
	for y in Height:
		for x in Width:
			var i := y*Width+x
			water_out = nem[i] *water_out_coef
			
				nem_update[i] -= water_out*4
				nem_update[i-1] += water_out
				nem_update[i+1] += water_out
				nem_update[i - Width] += water_out
				nem_update[i + Width] += water_out
