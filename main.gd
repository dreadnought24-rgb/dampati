extends Node2D

const CELL_SIZE := 32
const GRID_COLS := 4
const GRID_ROWS := 8
const SPAWN_ROWS := 2

const DOMINO_CARD_SCENE := preload("res://domino_card.tscn")
const DOMINO_PIECE_SCENE := preload("res://domino_piece.tscn")

var grid_data: Array = []
var grid_nodes: Array = []
var score: int = 0

var current_piece: Node2D = null
var current_col: int = 0
var current_row: int = 0
var current_orientation: String = "vertical"

func _ready() -> void:
	print("Grid siap: ", GRID_COLS, "x", GRID_ROWS)
	init_grid_data()
	spawn_piece()

func init_grid_data() -> void:
	grid_data.clear()
	grid_nodes.clear()
	for row in range(GRID_ROWS):
		var row_data := []
		var row_nodes := []
		for col in range(GRID_COLS):
			row_data.append(-1)
			row_nodes.append(null)
		grid_data.append(row_data)
		grid_nodes.append(row_nodes)

func grid_to_pixel(col: int, row: int) -> Vector2:
	return Vector2(col * CELL_SIZE, row * CELL_SIZE)

# Posisi sel B relatif terhadap sel A (anchor), tergantung orientasi
func get_cell_b_pos(col: int, row: int, orientation: String) -> Vector2i:
	if orientation == "vertical":
		return Vector2i(col, row + 1)
	else:
		return Vector2i(col + 1, row)

func spawn_piece() -> void:
	current_orientation = "vertical" if randi() % 2 == 0 else "horizontal"

	if current_orientation == "vertical":
		current_col = randi() % GRID_COLS
	else:
		current_col = randi() % (GRID_COLS - 1)
	current_row = 0

	var cell_b = get_cell_b_pos(current_col, current_row, current_orientation)

	if grid_data[current_row][current_col] != -1 or grid_data[cell_b.y][cell_b.x] != -1:
		game_over()
		return

	current_piece = DOMINO_PIECE_SCENE.instantiate()
	add_child(current_piece)
	current_piece.set_orientation(current_orientation)
	current_piece.set_values(randi() % 7, randi() % 7)
	current_piece.position = grid_to_pixel(current_col, current_row)

func can_move_to(new_col: int, new_row: int) -> bool:
	if new_col < 0 or new_col >= GRID_COLS or new_row < 0 or new_row >= GRID_ROWS:
		return false
	if grid_data[new_row][new_col] != -1:
		return false

	var cell_b = get_cell_b_pos(new_col, new_row, current_orientation)
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

func _process(delta: float) -> void:
	if current_piece == null:
		return

	if Input.is_action_just_pressed("ui_left"):
		try_move(-1)
	elif Input.is_action_just_pressed("ui_right"):
		try_move(1)

	if Input.is_action_just_pressed("ui_up"):
		current_piece.swap_values()

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
	var cell_b = get_cell_b_pos(current_col, current_row, current_orientation)
	var value_a = current_piece.value_a
	var value_b = current_piece.value_b

	current_piece.queue_free()
	current_piece = null

	place_card(current_row, current_col, value_a)
	place_card(cell_b.y, cell_b.x, value_b)

	check_matches()
	apply_gravity()
	spawn_piece()

func place_card(row: int, col: int, value: int) -> void:
	var card = DOMINO_CARD_SCENE.instantiate()
	add_child(card)
	card.position = grid_to_pixel(col, row)
	card.set_value(value)
	grid_data[row][col] = value
	grid_nodes[row][col] = card

func check_matches() -> void:
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS - 1):
			var a = grid_data[row][col]
			var b = grid_data[row][col + 1]
			if a != -1 and a == b:
				remove_card(row, col)
				remove_card(row, col + 1)
				score += 2
				print("Score: ", score)

	for row in range(GRID_ROWS - 1):
		for col in range(GRID_COLS):
			var a = grid_data[row][col]
			var b = grid_data[row + 1][col]
			if a != -1 and a == b:
				remove_card(row, col)
				remove_card(row + 1, col)
				score += 2
				print("Score: ", score)

func remove_card(row: int, col: int) -> void:
	var node = grid_nodes[row][col]
	if node != null:
		node.queue_free()
	grid_data[row][col] = -1
	grid_nodes[row][col] = null

func apply_gravity() -> void:
	for col in range(GRID_COLS):
		var values = []
		var nodes = []
		for row in range(GRID_ROWS):
			if grid_data[row][col] != -1:
				values.append(grid_data[row][col])
				nodes.append(grid_nodes[row][col])

		for row in range(GRID_ROWS):
			grid_data[row][col] = -1
			grid_nodes[row][col] = null

		var target_row = GRID_ROWS - 1
		for i in range(values.size() - 1, -1, -1):
			grid_data[target_row][col] = values[i]
			grid_nodes[target_row][col] = nodes[i]
			nodes[i].position = grid_to_pixel(col, target_row)
			target_row -= 1

func game_over() -> void:
	print("GAME OVER! Skor akhir: ", score)
	$Timer.stop()
	set_process(false)

func _draw() -> void:
	var spawn_color = Color(0.2, 0.2, 0.4, 0.5)
	draw_rect(Rect2(0, 0, GRID_COLS * CELL_SIZE, SPAWN_ROWS * CELL_SIZE), spawn_color)

	for col in range(GRID_COLS + 1):
		var x = col * CELL_SIZE
		draw_line(Vector2(x, 0), Vector2(x, GRID_ROWS * CELL_SIZE), Color.CYAN, 1.0)

	for row in range(GRID_ROWS + 1):
		var y = row * CELL_SIZE
		draw_line(Vector2(0, y), Vector2(GRID_COLS * CELL_SIZE, y), Color.CYAN, 1.0)
