extends Node2D

const CELL_SIZE := 32
const GRID_COLS := 4
const GRID_ROWS := 8
const SPAWN_ROWS := 2
const NO_PARTNER := Vector2i(-1, -1)

const DOMINO_CARD_SCENE := preload("res://domino_card.tscn")
const DOMINO_PIECE_SCENE := preload("res://domino_piece.tscn")

const FALL_STEP_DELAY := 0.15  # jeda tiap kartu turun 1 baris (detik), bisa disesuaikan

@export var chip_slot_scene: PackedScene

@onready var score_label: Label = $CanvasLayer/Label
@onready var round_label: Label = $CanvasLayer/RoundLabel
@onready var babak_label: Label = $CanvasLayer/BabakLabel
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var game_over_label: Label = $GameOverLayer/Label
#@onready var nilai_label: Label = $CanvasLayer/NilaiLabel
#@onready var match_label: Label = $CanvasLayer/MatchLabel
#@onready var hasil_label: Label = $CanvasLayer/HasilLabel
@onready var limit_score_label: Label = $CanvasLayer/LimitScore
@onready var next_piece_container: Node2D = $CanvasLayer/NextPieceContainer
@onready var chip_manager: Node = $ChipManager
@onready var chip_container: HBoxContainer = $CanvasLayer/ChipContainer
@onready var total_kartu_label: Label = $CanvasLayer/TotalKartu
@onready var base_label: Label = $CanvasLayer/Base  # atau $Base sesuai nama node di Scene Tree

var grid_data: Array = []
var grid_nodes: Array = []
var grid_partner: Array = []
var deck: Array = []
var score: float = 0.0
var combo_multiplier: int = 1   # ganti dari chain_value_streak dictionary

var current_piece: Node2D = null
var current_col: int = 0
var current_row: int = 0
var current_offset: Vector2i = Vector2i(0, 1)
var current_stage: int = 1   # 1 sampai 6
var current_round: int = 1   # 1 sampai 4 (per babak)

var next_piece_data: Vector2i = Vector2i(-1, -1)
var next_piece_offset: Vector2i = Vector2i(0, 1)
var next_piece_preview_node: Node2D = null

var max_kartu: int = 28
var sisa_kartu: int = 28

var base_reset_timer: SceneTreeTimer = null

func _ready() -> void:
	randomize()
	init_grid_data()
	build_deck()
	update_round_label()
	update_score_label()
	update_limit_score_ui()

	# 1. Load Chip Zero
	#var zero_chip = load("res://chip_power/chip_zero.tres")
	#if zero_chip:
		#chip_manager.add_chip(zero_chip)

	# 2. Load Chip One
	#var one_chip = load("res://chip_power/chip_balak.tres") # Sesuaikan nama file .tres kamu
	#if one_chip:
		#chip_manager.add_chip(one_chip)

	# 3. Tampilkan seluruh chip yang terpasang ke UI
	render_chip_slots()
	
	reset_total_kartu()
	spawn_piece()

func init_grid_data() -> void:
	grid_data.clear()
	grid_nodes.clear()
	grid_partner.clear()
	for row in range(GRID_ROWS):
		var row_data := []
		var row_nodes := []
		var row_partner := []
		for col in range(GRID_COLS):
			row_data.append(-1)
			row_nodes.append(null)
			row_partner.append(NO_PARTNER)
		grid_data.append(row_data)
		grid_nodes.append(row_nodes)
		grid_partner.append(row_partner)

func grid_to_pixel(col: int, row: int) -> Vector2:
	return Vector2(
		col * CELL_SIZE + 192,
		row * CELL_SIZE + 32
	)

func get_cell_b_pos(col: int, row: int, offset: Vector2i) -> Vector2i:
	return Vector2i(col + offset.x, row + offset.y)

func spawn_piece() -> void:
	if next_piece_data == Vector2i(-1, -1):
		prepare_next_piece()
		if next_piece_data == Vector2i(-1, -1):
			win_game()
			return

	# --- ACAK ORIENTASI SAAT MASUK ARENA ---
	current_offset = Vector2i(0, 1) if randi() % 2 == 0 else Vector2i(1, 0)

	if current_offset.x == 1:
		current_col = randi() % (GRID_COLS - 1)
	else:
		current_col = randi() % GRID_COLS
	current_row = 0

	var cell_b = get_cell_b_pos(current_col, current_row, current_offset)

	if grid_data[current_row][current_col] != -1 or grid_data[cell_b.y][cell_b.x] != -1:
		game_over()
		return

	# Pindahkan node dari Next Card ke Arena
	if next_piece_preview_node != null:
		current_piece = next_piece_preview_node
		next_piece_container.remove_child(current_piece)
		add_child(current_piece)
		next_piece_preview_node = null
		
		# --- UPDATE ORIENTASI KARTU SESUAI HASIL ACAKAN ARENA ---
		current_piece.set_cell_b_offset(current_offset)
	else:
		current_piece = DOMINO_PIECE_SCENE.instantiate()
		add_child(current_piece)
		current_piece.set_cell_b_offset(current_offset)
		current_piece.set_values(next_piece_data.x, next_piece_data.y)

	current_piece.position = grid_to_pixel(current_col, current_row)
	
# --- KURANGI KARTU DAN UPDATE UI DI SINI ---
	sisa_kartu -= 1
	update_total_kartu_ui()

	# Siapkan kartu berikutnya untuk UI Next Piece
	prepare_next_piece()
	
func can_move_to(new_col: int, new_row: int) -> bool:
	if new_col < 0 or new_col >= GRID_COLS or new_row < 0 or new_row >= GRID_ROWS:
		return false
	if grid_data[new_row][new_col] != -1:
		return false

	var cell_b = get_cell_b_pos(new_col, new_row, current_offset)
	if cell_b.x < 0 or cell_b.x >= GRID_COLS or cell_b.y < 0 or cell_b.y >= GRID_ROWS:
		return false
	if grid_data[cell_b.y][cell_b.x] != -1:
		return false

	return true

func try_move(direction: int) -> void:
	var new_col = current_col + direction
	if can_move_to(new_col, current_row):
		current_col = new_col
		current_piece.position = grid_to_pixel(current_col, current_row)

func try_rotate() -> void:
	var new_offset = Vector2i(-current_offset.y, current_offset.x)
	var cell_b = get_cell_b_pos(current_col, current_row, new_offset)

	if cell_b.x < 0 or cell_b.x >= GRID_COLS or cell_b.y < 0 or cell_b.y >= GRID_ROWS:
		return
	if grid_data[cell_b.y][cell_b.x] != -1:
		return

	current_offset = new_offset
	current_piece.set_cell_b_offset(new_offset)

func _process(delta: float) -> void:
	if current_piece == null:
		return

	if Input.is_action_just_pressed("ui_left"):
		try_move(-1)
	elif Input.is_action_just_pressed("ui_right"):
		try_move(1)

	if Input.is_action_just_pressed("ui_up"):
		current_piece.swap_values()

	if Input.is_action_just_pressed("rotate"):
		try_rotate()

	if Input.is_action_just_pressed("ui_accept"):
		hard_drop()

func _on_timer_timeout() -> void:
	if current_piece == null:
		return

	var next_row = current_row + 1
	if can_move_to(current_col, next_row):
		current_row = next_row
		current_piece.position = grid_to_pixel(current_col, current_row)
	else:
		land_piece()

func hard_drop() -> void:
	while can_move_to(current_col, current_row + 1):
		current_row += 1
	current_piece.position = grid_to_pixel(current_col, current_row)
	land_piece()
	$Timer.start()

func land_piece() -> void:
	combo_multiplier = 1
	
	var cell_b = get_cell_b_pos(current_col, current_row, current_offset)
	var value_a = current_piece.value_a
	var value_b = current_piece.value_b

	current_piece.queue_free()
	current_piece = null

	place_card(current_row, current_col, value_a, cell_b)
	place_card(cell_b.y, cell_b.x, value_b, Vector2i(current_col, current_row))

	var land_positions: Array[Vector2i] = [
		Vector2i(current_col, current_row),
		cell_b
	]
	chip_manager.trigger_piece_landed(grid_data, grid_nodes, land_positions)

	await apply_free_fall()
	while check_matches():
		await apply_free_fall()

	spawn_piece()

func place_card(row: int, col: int, value: int, partner_pos: Vector2i = NO_PARTNER) -> void:
	var card = DOMINO_CARD_SCENE.instantiate()
	add_child(card)
	card.position = grid_to_pixel(col, row)
	card.set_value(value)
	grid_data[row][col] = value
	grid_nodes[row][col] = card
	grid_partner[row][col] = partner_pos

func check_matches() -> bool:
	var visited := {}
	var groups := []
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var pos = Vector2i(col, row)
			if grid_data[row][col] == -1 or visited.has(pos):
				continue
			var value = grid_data[row][col]
			var group = flood_fill(pos, value, visited)
			if group.size() >= 2:
				groups.append(group)

	var found_match = false
	for group in groups:
		var p_first = group[0]
		var domino_value = grid_data[p_first.y][p_first.x]
		if group.size() == 2:
			var p1 = group[0]
			var p2 = group[1]
			if grid_partner[p1.y][p1.x] == p2:
				continue

		# --- 1. Tentukan Posisi Yang Akan Dihapus ---
		var tiles_to_remove: Array[Vector2i] = []
		for pos in group:
			if not tiles_to_remove.has(pos):
				tiles_to_remove.append(pos)

		# --- 2. CEK KARTU BIRU (The Rook Effect) ---
		var is_blue_triggered: bool = false
		for pos in group:
			var card_node = grid_nodes[pos.y][pos.x]
			if card_node != null and "card_color_type" in card_node:
				if card_node.card_color_type == "blue":
					is_blue_triggered = true
					print("🔥 EFEK KARTU BIRU: Meledakkan baris ", pos.y, " & kolom ", pos.x)

					# Tambah Baris (Kiri-Kanan)
					for target_col in range(GRID_COLS):
						var target_pos = Vector2i(target_col, pos.y)
						if grid_data[pos.y][target_col] != -1 and not tiles_to_remove.has(target_pos):
							tiles_to_remove.append(target_pos)

					# Tambah Kolom (Atas-Bawah)
					for target_row in range(GRID_ROWS):
						var target_pos = Vector2i(pos.x, target_row)
						if grid_data[target_row][pos.x] != -1 and not tiles_to_remove.has(target_pos):
							tiles_to_remove.append(target_pos)

		# --- 3. Hitung Total Skor Seluruh Kartu Yang Hancur Dalam 1 Match ---
		var total_base_earned: int = 0
		var valid_tiles_count: int = 0

		for pos in tiles_to_remove:
			var tile_val = grid_data[pos.y][pos.x]
			if tile_val >= 0:
				total_base_earned += tile_val
				valid_tiles_count += 1

		if valid_tiles_count > 0:
			# --- DETEKSI KARTU BALAK (DOUBLE) ---
			var is_double_match: bool = false
			for pos in group:
				var partner_pos = grid_partner[pos.y][pos.x]
				if partner_pos != Vector2i(-1, -1):
					var partner_val = grid_data[partner_pos.y][partner_pos.x]
					# Jika nilai sisi partner sama dengan nilai match (domino_value) -> Kartu Balak!
					if partner_val == domino_value:
						is_double_match = true
						break
						


			# Hitung skor murni dari ChipManager dengan menyertakan status balak
			var final_earned: float = chip_manager.calculate_final_score(total_base_earned, tiles_to_remove, domino_value, is_double_match)
			
			# Tambahkan LANGSUNG ke score
			score += final_earned

			for pos in tiles_to_remove:
				remove_card(pos.y, pos.x)

			update_score_label()
			found_match = true
			
			print("DEBUG MATCH: Base=", total_base_earned, " | Is Double=", is_double_match, " | Final Earned=", final_earned, " | Score Sekarang=", score)
			
			show_base_earned(total_base_earned)
			#update_base_label(total_base_earned)

	return found_match
## --- 3. Hitung Total Skor & Kalkulasi Chip Seluruh Kartu Yang Hancur ---
		#var total_base_earned: int = 0
		#var total_final_earned: int = 0
		#var valid_tiles_count: int = 0
#
		## Hitung skor dasar dan pemicu chip untuk SETIAP kartu yang hancur
		#for pos in tiles_to_remove:
			#var tile_val = grid_data[pos.y][pos.x]
			#if tile_val >= 0:
				#total_base_earned += tile_val
				#valid_tiles_count += 1
				#
				## Hitung skor kartu ini beserta pemicu chip-nya (seperti Chip Zero, One, dll)
				#var tile_final_score = chip_manager.calculate_final_score(tile_val, tiles_to_remove, tile_val)
				#total_final_earned += tile_final_score
#
		## HANYA PROSES SKOR JIKA ADA KARTU VALID (>= 0) YANG HANCUR
		#if valid_tiles_count > 0:
			#score += total_final_earned
#
			## --- 4. Eksekusi Penghapusan Kartu ---
			#for pos in tiles_to_remove:
				#remove_card(pos.y, pos.x)
#
			#update_score_label()
			#found_match = true
			#print("Match! Total ", valid_tiles_count, " kartu hancur (Base: ", total_base_earned, ") | Final +", total_final_earned, " poin. Total Skor: ", score)
			
			#remove_card(pos.y, pos.x)
		#var earned = domino_value * group.size() * combo_multiplier
		#score += earned
		#update_score_label()
		#found_match = true
		#print("Match ", group.size(), " kartu nilai ", domino_value, " x", combo_multiplier, " combo = +", earned, " poin. Total: ", score)

	#if found_match:
		#combo_multiplier += 1   # naikkan combo untuk wave berikutnya (kalau ada chain lanjutan)
#
	#return found_match

func flood_fill(start: Vector2i, value: int, visited: Dictionary) -> Array:
	var stack = [start]
	var group = []

	while stack.size() > 0:
		var pos = stack.pop_back()

		if visited.has(pos):
			continue
		if pos.x < 0 or pos.x >= GRID_COLS or pos.y < 0 or pos.y >= GRID_ROWS:
			continue
		if grid_data[pos.y][pos.x] != value:
			continue

		visited[pos] = true
		group.append(pos)

		stack.append(Vector2i(pos.x + 1, pos.y))
		stack.append(Vector2i(pos.x - 1, pos.y))
		stack.append(Vector2i(pos.x, pos.y + 1))
		stack.append(Vector2i(pos.x, pos.y - 1))

	return group

#func remove_card(row: int, col: int) -> void:
	#var partner_pos = grid_partner[row][col]
	#if partner_pos != NO_PARTNER:
		## yatim-kan pasangannya (kalau pasangannya masih ada di posisi itu)
		#if grid_partner[partner_pos.y][partner_pos.x] == Vector2i(col, row):
			#grid_partner[partner_pos.y][partner_pos.x] = NO_PARTNER
#
	#var node = grid_nodes[row][col]
	#if node != null:
		#node.queue_free()
	#grid_data[row][col] = -1
	#grid_nodes[row][col] = null
	#grid_partner[row][col] = NO_PARTNER

func remove_card(row: int, col: int) -> void:
	# 1. Cek apakah kartu yang akan dihapus ini memiliki pasangan
	var partner_pos = grid_partner[row][col]

	# 2. Jika punya pasangan, amankan kartu pasangannya!
	# Putuskan hubungan dari dua arah agar keping pasangannya TIDAK IKUT HANCUR
	if partner_pos != Vector2i(-1, -1):
		# Kartu pasangannya sekarang resmi menjadi kartu tunggal (independen)
		grid_partner[partner_pos.y][partner_pos.x] = Vector2i(-1, -1)
		# Kosongkan juga referensi pasangan kartu ini
		grid_partner[row][col] = Vector2i(-1, -1)

	# 3. Hapus HANYA keping yang berada di koordinat (row, col) ini
	grid_data[row][col] = -1
	if grid_nodes[row][col] != null:
		grid_nodes[row][col].queue_free()
		grid_nodes[row][col] = null

func apply_free_fall() -> void:
	var moved = true
	while moved:
		moved = free_fall_step()
		if moved:
			await get_tree().create_timer(FALL_STEP_DELAY).timeout

func free_fall_step() -> bool:
	var moved := false
	var processed := {}

	for row in range(GRID_ROWS - 1, -1, -1):
		for col in range(GRID_COLS):
			if grid_data[row][col] == -1:
				continue

			var pos = Vector2i(col, row)
			if processed.has(pos):
				continue

			var partner = grid_partner[row][col]

			if partner == NO_PARTNER:
				if row + 1 < GRID_ROWS and grid_data[row + 1][col] == -1:
					move_cell(pos, Vector2i(col, row + 1))
					moved = true
				processed[pos] = true
			else:
				if processed.has(partner):
					continue

				var dest_pos = Vector2i(pos.x, pos.y + 1)
				var dest_partner = Vector2i(partner.x, partner.y + 1)
				var can_fall = true

				if dest_pos.y >= GRID_ROWS or dest_partner.y >= GRID_ROWS:
					can_fall = false
				else:
					if dest_pos != partner and grid_data[dest_pos.y][dest_pos.x] != -1:
						can_fall = false
					if dest_partner != pos and grid_data[dest_partner.y][dest_partner.x] != -1:
						can_fall = false

				if can_fall:
					move_pair(pos, partner, dest_pos, dest_partner)
					moved = true

				processed[pos] = true
				processed[partner] = true

	return moved

func move_cell(from_pos: Vector2i, to_pos: Vector2i) -> void:
	grid_data[to_pos.y][to_pos.x] = grid_data[from_pos.y][from_pos.x]
	grid_nodes[to_pos.y][to_pos.x] = grid_nodes[from_pos.y][from_pos.x]
	grid_partner[to_pos.y][to_pos.x] = NO_PARTNER
	grid_nodes[to_pos.y][to_pos.x].position = grid_to_pixel(to_pos.x, to_pos.y)

	grid_data[from_pos.y][from_pos.x] = -1
	grid_nodes[from_pos.y][from_pos.x] = null
	grid_partner[from_pos.y][from_pos.x] = NO_PARTNER

func move_pair(pos_a: Vector2i, pos_b: Vector2i, dest_a: Vector2i, dest_b: Vector2i) -> void:
	var val_a = grid_data[pos_a.y][pos_a.x]
	var val_b = grid_data[pos_b.y][pos_b.x]
	var node_a = grid_nodes[pos_a.y][pos_a.x]
	var node_b = grid_nodes[pos_b.y][pos_b.x]

	grid_data[pos_a.y][pos_a.x] = -1
	grid_nodes[pos_a.y][pos_a.x] = null
	grid_partner[pos_a.y][pos_a.x] = NO_PARTNER
	grid_data[pos_b.y][pos_b.x] = -1
	grid_nodes[pos_b.y][pos_b.x] = null
	grid_partner[pos_b.y][pos_b.x] = NO_PARTNER

	grid_data[dest_a.y][dest_a.x] = val_a
	grid_nodes[dest_a.y][dest_a.x] = node_a
	grid_partner[dest_a.y][dest_a.x] = dest_b
	node_a.position = grid_to_pixel(dest_a.x, dest_a.y)

	grid_data[dest_b.y][dest_b.x] = val_b
	grid_nodes[dest_b.y][dest_b.x] = node_b
	grid_partner[dest_b.y][dest_b.x] = dest_a
	node_b.position = grid_to_pixel(dest_b.x, dest_b.y)

func game_over() -> void:
	print("GAME OVER! Skor akhir: ", score)
	$Timer.stop()
	set_process(false)
	game_over_label.text = "Game Over\nSkor: " + str(score)
	game_over_layer.visible = true

func _on_restart_button_pressed() -> void:
	restart_game()

#func restart_game() -> void:
	## ... (kode pembersihan kartu & grid lama Anda)
#
	#if next_piece_preview_node != null:
		#next_piece_preview_node.queue_free()
		#next_piece_preview_node = null
#
	#next_piece_data = Vector2i(-1, -1)
#
	## ... (lanjutan reset score, init_grid_data, build_deck)
	#
	#spawn_piece() # Ini otomatis akan mengisi arena dan menyiapkan next piece baru
	
func restart_game() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if grid_nodes[row][col] != null:
				grid_nodes[row][col].queue_free()

	if current_piece != null:
		current_piece.queue_free()
		current_piece = null

	score = 0
	current_stage = 1
	current_round = 1
	update_score_label()
	init_grid_data()
	build_deck()
	game_over_layer.visible = false
	set_process(true)
	$Timer.start()
	spawn_piece()

#func _draw() -> void:
	#var spawn_color = Color(0.2, 0.2, 0.4, 0.5)
	#draw_rect(Rect2(0, 0, GRID_COLS * CELL_SIZE, SPAWN_ROWS * CELL_SIZE), spawn_color)
#
	#for col in range(GRID_COLS + 1):
		#var x = col * CELL_SIZE
		#draw_line(Vector2(x, 0), Vector2(x, GRID_ROWS * CELL_SIZE), Color.CYAN, 1.0)
#
	#for row in range(GRID_ROWS + 1):
		#var y = row * CELL_SIZE
		#draw_line(Vector2(0, y), Vector2(GRID_COLS * CELL_SIZE, y), Color.CYAN, 1.0)

func update_score_label() -> void:
	score_label.text = str(score)
	
func build_deck() -> void:
	deck.clear()
	for a in range(7):
		for b in range(a, 7):
			deck.append(Vector2i(a, b))
	deck.shuffle()
	
func win_game() -> void:
	var limit = get_round_score_limit()
	if score >= limit:
		advance_round()
	else:
		fail_round()

func get_round_score_limit() -> int:
	var global_round = (current_stage - 1) * 4 + current_round
	return global_round * 100
	
func advance_round() -> void:
	print("Ronde lolos! Skor: ", score, " / Limit: ", get_round_score_limit())

	if is_boss_round():
		print("[Placeholder] Ini seharusnya boss battle, tapi belum diimplementasi. Lanjut normal dulu.")
		# TODO: nanti panggil fungsi boss battle di sini, sebelum lanjut ke ronde berikutnya

	current_round += 1
	if current_round > 4:
		current_round = 1
		current_stage += 1

	if current_stage > 6:
		win_all_stages()
		return

	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if grid_nodes[row][col] != null:
				grid_nodes[row][col].queue_free()
	init_grid_data()
	build_deck()
	update_round_label()
	update_limit_score_ui()
	reset_total_kartu()
	spawn_piece()
	
	
func update_limit_score_ui() -> void:
	if limit_score_label:
		limit_score_label.text = str(get_round_score_limit())
	
func fail_round() -> void:
	print("GAGAL! Skor: ", score, " tidak mencapai limit ", get_round_score_limit())
	$Timer.stop()
	set_process(false)
	game_over_label.text = "Gagal di Babak " + str(current_stage) + " Ronde " + str(current_round) + "\nSkor: " + str(score) + " / Limit: " + str(get_round_score_limit())
	game_over_layer.visible = true
	
func win_all_stages() -> void:
	print("SEMUA BABAK SELESAI! Skor akhir: ", score)
	$Timer.stop()
	set_process(false)
	game_over_label.text = "Semua Babak Selesai!\nSkor Akhir: " + str(score)
	game_over_layer.visible = true
	
func update_round_label() -> void:
	if babak_label:
		babak_label.text = "Babak " + str(current_stage)
	
	if round_label:
		round_label.text = "Ronde " + str(current_round)

func is_boss_round() -> bool:
	return current_round == 4
	
func prepare_next_piece() -> void:
	if deck.size() == 0:
		next_piece_data = Vector2i(-1, -1)
		return

	# Hapus visual preview lama jika ada
	if next_piece_preview_node != null:
		next_piece_preview_node.queue_free()
		next_piece_preview_node = null

	# 1. Ambil data domino dari deck
	var domino = deck.pop_back()
	var val_a = domino.x
	var val_b = domino.y
	if randi() % 2 == 0:
		var temp = val_a
		val_a = val_b
		val_b = temp

	next_piece_data = Vector2i(val_a, val_b)
	next_piece_offset = Vector2i(0, 1)

	next_piece_preview_node = DOMINO_PIECE_SCENE.instantiate()
	next_piece_container.add_child(next_piece_preview_node)
	next_piece_preview_node.set_cell_b_offset(next_piece_offset)
	next_piece_preview_node.set_values(val_a, val_b)
	next_piece_preview_node.position = Vector2.ZERO
	
# Fungsi untuk mencari kelompok kartu bernilai sama yang saling terhubung (Atas, Bawah, Kiri, Kanan)
func get_connected_group(start_row: int, start_col: int, target_value: int, visited: Array) -> Array[Vector2i]:
	var group: Array[Vector2i] = []
	var queue: Array[Vector2i] = [Vector2i(start_col, start_row)]
	visited[start_row][start_col] = true

	var directions = [
		Vector2i(0, -1), # Atas
		Vector2i(0, 1),  # Bawah
		Vector2i(-1, 0), # Kiri
		Vector2i(1, 0)   # Kanan
	]

	while queue.size() > 0:
		var current = queue.pop_front()
		group.append(current)

		for dir in directions:
			var neighbor_col = current.x + dir.x
			var neighbor_row = current.y + dir.y

			if neighbor_row >= 0 and neighbor_row < GRID_ROWS and neighbor_col >= 0 and neighbor_col < GRID_COLS:
				if not visited[neighbor_row][neighbor_col] and grid_data[neighbor_row][neighbor_col] == target_value:
					visited[neighbor_row][neighbor_col] = true
					queue.append(Vector2i(neighbor_col, neighbor_row))

	return group
	
	
func render_chip_slots() -> void:
	if chip_container == null or chip_slot_scene == null:
		return

	# Hapus instance lama agar tidak menumpuk
	for child in chip_container.get_children():
		child.queue_free()

	# Rendernya HARUS dimasukkan ke dalam chip_container, bukan ke Main langsung
	for chip in chip_manager.equipped_chips:
		var slot_instance = chip_slot_scene.instantiate()
		chip_container.add_child(slot_instance)

		if slot_instance.has_method("setup_chip"):
			slot_instance.setup_chip(chip)


func update_total_kartu_ui() -> void:
	if total_kartu_label:
		total_kartu_label.text = str(sisa_kartu) + "/" + str(max_kartu)
		
# Panggil fungsi ini saat Game Start, Restart, atau Berpindah Ronde
func reset_total_kartu() -> void:
	sisa_kartu = max_kartu
	update_total_kartu_ui()
	
func update_base_label(value: int) -> void:
	if base_label:
		base_label.text = str(value)


func show_base_earned(value: int) -> void:
	if not base_label:
		return

	# Update teks dengan nilai base yang baru dapat
	base_label.text = str(value)
	
	# Buat timer 0.5 detik baru
	base_reset_timer = get_tree().create_timer(0.75)
	
	# Tunggu timer selesai
	await base_reset_timer.timeout
	
	# Cek apakah timer ini masih timer yang aktif terakhir kali dipanggil.
	# Jika pemain bergerak lagi sebelum 0.5 detik, base_reset_timer akan diganti,
	# sehingga kode di bawah ini diputus/diabaikan untuk gerakan lama.
	if base_reset_timer and base_reset_timer.time_left <= 0:
		base_label.text = "0"
