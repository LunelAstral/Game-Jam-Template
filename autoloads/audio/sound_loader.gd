class_name SoundLoader

func load_audio() -> void:
	load_ost()
	load_sfx()
	load_ui()
	load_ambient()

func load_ost() -> void:
	# Add OST loads here
	var song_list : Array[AudioStream] = []
	
	for song in song_list:
		song.resource_name = grab_name(song.resource_path)
		MusicManager.add_ost(song)

func load_sfx() -> void:
	# Add SFX loads here
	var sfx_list : Array[AudioStream] = []
	
	for sfx in sfx_list:
		sfx.resource_name = grab_name(sfx.resource_path)
		SoundManager.add_sound(sfx)

func load_ui() -> void:
	# Add UI loads here
	pass

func load_ambient() -> void:
	# Add Ambient loads here
	pass

func grab_name(path: String) -> String:
	return path.split("/")[path.split("/").size() - 1].split(".")[0]
