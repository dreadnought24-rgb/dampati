extends Node
class_name ChipManager

# Menggunakan Array khusus berisi ChipData
var equipped_chips: Array[ChipData] = []

func add_chip(chip: ChipData) -> void:
	if chip != null and not equipped_chips.has(chip):
		equipped_chips.append(chip)

func remove_chip(chip: ChipData) -> void:
	equipped_chips.erase(chip)

# Pemicu saat kartu mendarat di arena
func trigger_piece_landed(grid_data: Array, grid_nodes: Array, land_positions: Array[Vector2i]) -> void:
	for chip in equipped_chips:
		if chip != null and chip.is_active:
			if chip.trigger_type == ChipData.TriggerType.ON_PIECE_LANDED:
				# Logika khusus piece landed jika ada di chip terkait
				pass

# Kalkulasi Skor Dinamis berdasarkan ChipData
# Ubah return type dari `-> float:` menjadi `-> Dictionary:`
func calculate_final_score(base_score: int, group: Array, card_value: int, is_double: bool = false) -> Dictionary:
	var total_flat: int = 0
	var total_mult_plus: float = 0.0
	var total_mult_times: float = 1.0

	for chip in equipped_chips:
		if chip != null and chip.is_active:
			if chip.trigger_type == ChipData.TriggerType.ON_SCORE:
				# Cek syarat balak: Jika chip butuh balak tapi match bukan balak, lewati chip ini
				if chip.requires_double and not is_double:
					continue

				if chip.target_tile_value == -1 or chip.target_tile_value == card_value:
					total_flat += chip.bonus_flat_chips
					total_mult_plus += chip.bonus_mult_plus
					total_mult_times *= chip.bonus_mult_times

	var effective_base = base_score
	if effective_base == 0 and total_mult_plus > 0:
		effective_base = 1

	var multiplier: float = (1.0 + total_mult_plus) * total_mult_times
	var result: float = (effective_base + total_flat) * multiplier

	# Mengembalikan Dictionary berisi Skor Akhir dan Multiplier
	return {
		"skor_akhir": result,
		"pengali": multiplier
	}
