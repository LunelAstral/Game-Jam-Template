extends Node

#region Loading Up
func _ready() -> void:
	# Loading up sounds and then deleting the sound_loader as it's no longer necessary
	var sound_loader = SoundLoader.new()
	sound_loader.load_audio()
	sound_loader = null
	
	print(MusicManager.song_pool)

#region Helpers
func delay(time: float) -> void:
	await get_tree().create_timer(time).timeout
#endregion
