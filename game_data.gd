extends Node

var koin: int = 0
var equipped_chips: Array[ChipData] = []
var current_stage: int = 1
var current_round: int = 1
var score: float = 0.0

func add_chip(chip: ChipData) -> void:
	equipped_chips.append(chip)

func reset_all() -> void:
	koin = 0
	equipped_chips.clear()
	current_stage = 1
	current_round = 1
	score = 0.0
