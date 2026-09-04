class_name ChipData
extends Resource

# --- IDENTITAS UTAMA CHIP ---
@export var chip_id: String = "chip_id"
@export var chip_name: String = "Nama Chip"
@export_multiline var description: String = "Deskripsi chip..."
@export var icon: Texture2D
@export var is_active: bool = true
@export var price: int = 10

# --- TIPE TRIGGER (KAPAN EFEK AKTIF) ---
enum TriggerType {
	ON_SCORE,        # Aktif saat match/kalkulasi skor
	ON_PIECE_LANDED, # Aktif saat kartu mendarat di arena
	ON_ROUND_START,  # Aktif di awal ronde
	ON_ROUND_END,    # Aktif di akhir ronde
	PASSIVE          # Efek pasif terus menerus
}
@export var trigger_type: TriggerType = TriggerType.ON_SCORE

# --- NILAI EFEK SKOR ---
@export var bonus_flat_chips: int = 0      # Tambahan Poin Flat
@export var bonus_mult_plus: float = 0.0   # Tambahan Mult (+1, +5, +10)
@export var bonus_mult_times: float = 1.0  # Perkalian Mult (x1.5, x2, x3)

# --- SYARAT KONDISIONAL ---
@export var target_tile_value: int = -1    # -1 = Semua angka, 0-6 = Angka spesifik
@export var require_balak: bool = false    # Khusus kartu kembar/balak

# Tambahkan di bagian variabel export ChipData
@export var requires_double: bool = false # Centang true jika chip hanya aktif untuk kartu Balak
