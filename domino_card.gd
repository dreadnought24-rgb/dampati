extends Node2D

var value: int = 0

@onready var sprite: Sprite2D = $Sprite2D

var textures: Array[Texture2D] = [
	preload("res://assets/sprites/l0_sprite_1.png"),
	preload("res://assets/sprites/l0_sprite_2.png"),
	preload("res://assets/sprites/l0_sprite_3.png"),
	preload("res://assets/sprites/l0_sprite_4.png"),
	preload("res://assets/sprites/l0_sprite_5.png"),
	preload("res://assets/sprites/l0_sprite_6.png"),
	preload("res://assets/sprites/l0_sprite_7.png"),
]

var card_color_type: String = "normal" # Menandai status warna kartu



func set_value(v: int) -> void:
	value = v
	sprite.texture = textures[v]
	
# Fungsi untuk mengubah warna background/overlay kartu
func set_card_color(color_name: String, color_value: Color) -> void:
	card_color_type = color_name
	# Mengubah modulasi warna visual sprite secara permanen
	modulate = color_value
	
