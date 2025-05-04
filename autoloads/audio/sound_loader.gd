class_name SoundLoader

# How setup work is within _list you preload the sound so it's an AudioStream

func load_audio() -> void:
	load_ost()
	load_sfx()
	load_ui()
	load_ambient()

func load_ost() -> void:
	# Add OST loads here
	var song_list : Dictionary[int, Array] = {}
	
	for song in song_list.values():
		song.get(0).resource_name = grab_name(song.get(0).resource_path)
		MusicManager.add_ost(song.get(0), song.get(1))

func load_sfx() -> void:
	# Add SFX loads here
	var sfx_list : Array[AudioStream] = []
	
	for sfx in sfx_list:
		sfx.resource_name = grab_name(sfx.resource_path)
		SoundManager.add_sound(sfx)

func load_ui() -> void:
	# Add UI loads here
	var ui_list : Array[AudioStream] = []
	
	for ui in ui_list:
		ui.resource_name = grab_name(ui.resource_path)
		SoundManager.add_sound(ui)

func load_ambient() -> void:
	# Add Ambient loads here
	var ambient_list : Array[AudioStream] = []
	
	for ambient in ambient_list:
		ambient.resource_name = grab_name(ambient.resource_path)
		SoundManager.add_sound(ambient)

func grab_name(path: String) -> String:
	return path.split("/")[path.split("/").size() - 1].split(".")[0]
