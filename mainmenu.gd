extends Node2D

# Path ke scene game utama kamu (sesuaikan lokasi filenya)
const MAIN_GAME_SCENE: String = "res://main.tscn"

@onready var play_button: Button = $Background/Button
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var button: AudioStreamPlayer2D = $Background/TextureButton/button

func _ready() -> void:
	# Menghubungkan signal tombol via kode saat scene siap
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
		
	audio_stream_player_2d.play()

func _on_play_button_pressed() -> void:
	
	# Pindah scene dari MainMenu ke MainGame
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)
	button.play()
	

# Fungsi untuk keluar dari game
func _on_quit_button_pressed() -> void:
	get_tree().quit()
	button.play()


func _on_button_pressed() -> void:
	pass # Replace with function body.
