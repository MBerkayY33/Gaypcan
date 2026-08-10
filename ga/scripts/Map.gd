class_name Map extends RefCounted

const Width := 256
const Height := 256



var nem:       PackedFloat32Array
var gunes:     PackedFloat32Array
var verim:     PackedFloat32Array

func _init() -> void:
	var n = Width * Height
	nem.resize(n)
	gunes.resize(n)
	verim.resize(n)

	
var img = Image.create(Width,Height,false,Image.FORMAT_RGB8)	

func produce_ground():
	pass
