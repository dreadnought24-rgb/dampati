# res://chip_the_rook.gd
class_name ChipTheRook
extends Chip

func _init() -> void:
	chip_name = "The Rook"
	description = "Jika kartu berhenti di kolom/baris ke-6 dari bawah, ubah warnanya menjadi biru."

# Dipanggil otomatis oleh ChipManager saat ada kartu mendarat
func on_piece_landed(grid_data: Array, grid_nodes: Array, land_positions: Array[Vector2i]) -> void:
	var grid_height: int = grid_data.size()
	var target_row_index: int = grid_height - 6 

	print("--- ROOK CHECK ---")
	print("Grid Height: ", grid_height, " | Target Row Index (Ke-6 dr bawah): ", target_row_index)

	for pos in land_positions:
		print("Kartu mendarat di posisi: Col ", pos.x, ", Row ", pos.y)
		if pos.y == target_row_index:
			var card_node = grid_nodes[pos.y][pos.x]
			if card_node != null:
				card_node.set_card_color("blue", Color(0.3, 0.5, 1.0))
				print("SUCCESS: Kartu di (", pos.x, ",", pos.y, ") BERUBAH JADI BIRU!")
			else:
				print("ERROR: card_node di grid_nodes bernilai NULL!")
