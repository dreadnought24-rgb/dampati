extends Node2D

var pool_chip: Array = [
	preload("res://Chip_power/chip_zero.tres"),
	preload("res://Chip_power/chip_one.tres"),
	preload("res://Chip_power/chip_two.tres"),
	preload("res://Chip_power/chip_three.tres"),
	preload("res://Chip_power/chip_four.tres"),
	preload("res://Chip_power/chip_five.tres"),
	preload("res://Chip_power/chip_six.tres"),
	preload("res://Chip_power/chip_balak.tres")
]

@onready var container = $CanvasLayer/HBoxContainer
@onready var koin_label = $CanvasLayer/koin
@onready var next_button = $CanvasLayer/nextbutton  # SESUAIKAN path tombol Next kamu

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	update_coin_display()
	generate_random_shop_items()

func update_coin_display() -> void:
	if koin_label:
		koin_label.text = str(GameData.koin) + " G"

func generate_random_shop_items() -> void:
	pool_chip.shuffle()
	var slot_items = container.get_children()

	for i in range(min(slot_items.size(), 3)):
		var slot_node = slot_items[i]
		var data_chip = pool_chip[i]

		var texture_button = slot_node.get_node("TextureButton")
		var label_harga = slot_node.get_node("LabelHarga")

		texture_button.texture_normal = data_chip.icon
		texture_button.disabled = false
		texture_button.modulate = Color(1, 1, 1, 1)
		label_harga.text = str(data_chip.price) + " G"

		if texture_button.pressed.is_connected(_on_chip_purchased):
			texture_button.pressed.disconnect(_on_chip_purchased)

		texture_button.pressed.connect(_on_chip_purchased.bind(data_chip, texture_button, label_harga))

func _on_chip_purchased(data_chip: ChipData, button: TextureButton, label: Label) -> void:
	if GameData.koin >= data_chip.price:
		GameData.koin -= data_chip.price
		update_coin_display()

		label.text = "SOLD!"
		button.disabled = true
		button.modulate = Color(0.3, 0.3, 0.3, 0.5)

		# --- SIMPAN KE GAMEDATA, BUKAN LANGSUNG KE MAIN ---
		GameData.add_chip(data_chip)
	else:
		print("Koin tidak cukup!")

func _on_next_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
