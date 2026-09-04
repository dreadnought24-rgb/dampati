extends Node2D

# --- ENUM WARNA KARTU ---
enum CardColor { NONE, BLUE, GREEN, YELLOW, BLACK, RED, PURPLE }

var value: int = 0
var card_color: CardColor = CardColor.NONE
var card_color_type: String = "normal" # Menyimpan representasi String untuk kompatibilitas

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

func set_value(v: int) -> void:
	value = v
	if sprite:
		sprite.texture = textures[v]

# --- FUNGSI UTAMA MENGUBAH WARNA KARTU ---
func set_card_color(new_color: CardColor) -> void:
	card_color = new_color
	update_background_visual()

func update_background_visual() -> void:
	match card_color:
		CardColor.NONE:
			card_color_type = "normal"
			modulate = Color(1.0, 1.0, 1.0, 1.0) # Warna asli
		CardColor.BLUE:
			card_color_type = "blue"
			modulate = Color(0.2, 0.6, 1.0, 1.0) # Biru
		CardColor.GREEN:
			card_color_type = "green"
			modulate = Color(0.2, 0.9, 0.3, 1.0) # Hijau
		CardColor.YELLOW:
			card_color_type = "yellow"
			modulate = Color(1.0, 0.85, 0.1, 1.0) # Kuning
		CardColor.BLACK:
			card_color_type = "black"
			modulate = Color(0.3, 0.3, 0.3, 1.0) # Hitam
		CardColor.RED:
			card_color_type = "red"
			modulate = Color(1.0, 0.25, 0.25, 1.0) # Merah
		CardColor.PURPLE:
			card_color_type = "purple"
			modulate = Color(0.7, 0.2, 0.9, 1.0) # Ungu
