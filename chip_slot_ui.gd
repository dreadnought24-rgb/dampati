extends TextureButton
class_name ChipSlotUI

var current_chip: ChipData = null

func setup_chip(chip_data: ChipData) -> void:
	current_chip = chip_data
	
	if current_chip:
		# Pasang tekstur ikon jika ada
		if current_chip.icon:
			texture_normal = current_chip.icon
		
		# Set Tooltip bawaan Godot (muncul saat mouse hover)
		tooltip_text = current_chip.chip_name + "\n" + current_chip.description
		
		update_visual_status()

func _pressed() -> void:
	if current_chip:
		current_chip.is_active = not current_chip.is_active
		update_visual_status()

func update_visual_status() -> void:
	if current_chip:
		if current_chip.is_active:
			modulate = Color(1.0, 1.0, 1.0, 1.0) # Terang/Aktif
		else:
			modulate = Color(0.4, 0.4, 0.4, 0.6) # Redup/Nonaktif
