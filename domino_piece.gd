extends Node2D

var value_a: int = 0
var value_b: int = 0
var cell_b_offset: Vector2i = Vector2i(0, 1)

@onready var cell_a: Sprite2D = $CellA
@onready var cell_b: Sprite2D = $CellB

var textures: Array[Texture2D] = [
	preload("res://assets/sprites/l0_sprite_1.png"),
	preload("res://assets/sprites/l0_sprite_2.png"),
	preload("res://assets/sprites/l0_sprite_3.png"),
	preload("res://assets/sprites/l0_sprite_4.png"),
	preload("res://assets/sprites/l0_sprite_5.png"),
	preload("res://assets/sprites/l0_sprite_6.png"),
	preload("res://assets/sprites/l0_sprite_7.png"),
]

func set_values(a: int, b: int) -> void:
	value_a = a
	value_b = b
	cell_a.texture = textures[a]
	cell_b.texture = textures[b]

func set_cell_b_offset(offset: Vector2i) -> void:
	cell_b_offset = offset
	cell_b.position = Vector2(offset.x * 32, offset.y * 32)

func swap_values() -> void:
	var temp = value_a
	value_a = value_b
	value_b = temp
	cell_a.texture = textures[value_a]
	cell_b.texture = textures[value_b]
