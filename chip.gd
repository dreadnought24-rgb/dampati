## res://chip.gd
#class_name Chip
#extends RefCounted
#
#var chip_name: String = "Base Chip"
#var description: String = ""
#var is_active: bool = true  # Flag untuk ON/OFF saat debugging
#
## --- FUNGSI KOSONG (Dipanggil saat kartu mendarat di grid) ---
#func on_piece_landed(grid_data: Array, grid_nodes: Array, land_positions: Array[Vector2i]) -> void:
	#pass
#
## --- FUNGSI KOSONG (Dipanggil saat hitung Flat Score: Base + Bonus) ---
#func modify_flat_score(current_flat: int, match_group: Array, domino_value: int) -> int:
	#return current_flat
#
## --- FUNGSI KOSONG (Dipanggil saat hitung MultPlus) ---
#func modify_mult_plus(current_mult_plus: float, match_group: Array, domino_value: int) -> float:
	#return current_mult_plus
	
	
	
class_name Chip
extends Resource

@export var chip_id: String = "base_chip"
@export var chip_name: String = "Base Chip"
@export_multiline var description: String = "Deskripsi chip..."
@export var icon: Texture2D
@export var is_active: bool = true  # Status aktif / nonaktif

# Override fungsi ini di setiap subclass chip spesifik
func apply_effect(base_score: int, group_size: int, card_value: int) -> Dictionary:
	# Retun nilai bonus: flat_chip, mult_plus, mult_times
	return {
		"bonus_flat": 0,
		"mult_plus": 0.0,
		"mult_times": 1.0
	}
