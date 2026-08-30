extends Node2D

const CELL_SIZE := 32
const GRID_COLS := 4
const GRID_ROWS := 8
const SPAWN_ROWS := 2
const NO_PARTNER := Vector2i(-1, -1)

const DOMINO_CARD_SCENE := preload("res://domino_card.tscn")
const DOMINO_PIECE_SCENE := preload("res://domino_piece.tscn")

const FALL_STEP_DELAY := 0.15  # jeda tiap kartu turun 1 baris (detik), bisa disesuaikan

@onready var score_label: Label = $CanvasLayer/Label
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var game_over_label: Label = $GameOverLayer/Label

var grid_data: Array = []
var grid_nodes: Array = []
var grid_partner: Array = []
var deck: Array = []
var score: int = 0
var combo_multiplier: int = 1   # ganti dari chain_value_streak dictionary

var current_piece: Node2D = null
var current_col: int = 0
var current_row: int = 0
var current_offset: Vector2i = Vector2i(0, 1)

func _ready() -> void:
	print("Grid siap: ", GRID_COLS, "x", GRID_ROWS)
	init_grid_data()
	build_deck()
	spawn_piece()
	update_score_label()

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
	return Vector2(col * CELL_SIZE, row * CELL_SIZE)

func get_cell_b_pos(col: int, row: int, offset: Vector2i) -> Vector2i:
	return Vector2i(col + offset.x, row + offset.y)

func spawn_piece() -> void:
	if deck.size() == 0:
		win_game()
		return

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

	var domino = deck.pop_back()
	var val_a = domino.x
	var val_b = domino.y
	if randi() % 2 == 0:
		var temp = val_a
		val_a = val_b
		val_b = temp

	current_piece = DOMINO_PIECE_SCENE.instantiate()
	add_child(current_piece)
	current_piece.set_cell_b_offset(current_offset)
	current_piece.set_values(val_a, val_b)
	current_piece.position = grid_to_pixel(current_col, current_row)
	
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

		for pos in group:
			remove_card(pos.y, pos.x)
		var earned = domino_value * group.size() * combo_multiplier
		score += earned
		update_score_label()
		found_match = true
		print("Match ", group.size(), " kartu nilai ", domino_value, " x", combo_multiplier, " combo = +", earned, " poin. Total: ", score)

	if found_match:
		combo_multiplier += 1   # naikkan combo untuk wave berikutnya (kalau ada chain lanjutan)

	return found_match

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

func remove_card(row: int, col: int) -> void:
	var partner_pos = grid_partner[row][col]
	if partner_pos != NO_PARTNER:
		# yatim-kan pasangannya (kalau pasangannya masih ada di posisi itu)
		if grid_partner[partner_pos.y][partner_pos.x] == Vector2i(col, row):
			grid_partner[partner_pos.y][partner_pos.x] = NO_PARTNER

	var node = grid_nodes[row][col]
	if node != null:
		node.queue_free()
	grid_data[row][col] = -1
	grid_nodes[row][col] = null
	grid_partner[row][col] = NO_PARTNER

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

func restart_game() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			if grid_nodes[row][col] != null:
				grid_nodes[row][col].queue_free()

	if current_piece != null:
		current_piece.queue_free()
		current_piece = null

	score = 0
	update_score_label()
	init_grid_data()
	build_deck()
	game_over_layer.visible = false
	set_process(true)
	$Timer.start()
	spawn_piece()

func _draw() -> void:
	var spawn_color = Color(0.2, 0.2, 0.4, 0.5)
	draw_rect(Rect2(0, 0, GRID_COLS * CELL_SIZE, SPAWN_ROWS * CELL_SIZE), spawn_color)

	for col in range(GRID_COLS + 1):
		var x = col * CELL_SIZE
		draw_line(Vector2(x, 0), Vector2(x, GRID_ROWS * CELL_SIZE), Color.CYAN, 1.0)

	for row in range(GRID_ROWS + 1):
		var y = row * CELL_SIZE
		draw_line(Vector2(0, y), Vector2(GRID_COLS * CELL_SIZE, y), Color.CYAN, 1.0)

func update_score_label() -> void:
	score_label.text = "Score: " + str(score)
	
func build_deck() -> void:
	deck.clear()
	for a in range(7):
		for b in range(a, 7):
			deck.append(Vector2i(a, b))
	deck.shuffle()
	
func win_game() -> void:
	print("MENANG! Semua domino habis. Skor akhir: ", score)
	$Timer.stop()
	set_process(false)
	game_over_label.text = "Menang!\nSemua domino habis\nSkor: " + str(score)
	game_over_layer.visible = true
