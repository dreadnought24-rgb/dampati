# boss_manager.gd
extends Node

enum BossType {
	NONE,
	GONDRONG,
	YELLOW,
	KADIV_KONSUM,
	FURRY,
	ATMIN,
	KOMDIS
}

var current_boss: int = BossType.NONE

# state khusus per-boss
var hand_age: Array = []   # array 2D paralel grid_data, isi jumlah "hand" kartu itu bertahan (Kadiv Konsum)

signal boss_activated(boss_type: int)
signal boss_cleared()

func activate_random_boss() -> void:
	var pool = [
		BossType.GONDRONG,
	]
	current_boss = pool[randi() % pool.size()]
	print("BOSS AKTIF: ", BossType.keys()[current_boss])
	emit_signal("boss_activated", current_boss)

func clear_boss() -> void:
	current_boss = BossType.NONE
	hand_age.clear()
	emit_signal("boss_cleared")

func is_active(type: int) -> bool:
	return current_boss == type

func init_hand_age(rows: int, cols: int) -> void:
	hand_age.clear()
	for r in range(rows):
		var row = []
		for c in range(cols):
			row.append(0)
		hand_age.append(row)

func reset_age(row: int, col: int) -> void:
	if hand_age.size() > row:
		hand_age[row][col] = 0

func tick_and_get_expired(grid_data: Array, rows: int, cols: int) -> Array:
	# panggil sekali per hand; return posisi yang harus dihapus (usia >= 6)
	var expired: Array = []
	for r in range(rows):
		for c in range(cols):
			if grid_data[r][c] != -1:
				hand_age[r][c] += 1
				if hand_age[r][c] >= 6:
					expired.append(Vector2i(c, r))
	return expired
