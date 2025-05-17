extends Node

#region Signals
signal finished_sound(sfx)
#endregion

#region Variable Definitions
var audio_players : Dictionary[Genum.BusID, Array]
var audio_player_count_per_group : int = 4
var sfx_pool : Dictionary[StringName, AudioStream] = {}
var ui_pool : Dictionary[StringName, AudioStream] = {}
var ambient_pool : Dictionary[StringName, AudioStream] = {}

var playing : Array[StringName]
#endregion

func _ready() -> void:
	setup_audio_players()

#region Setup Functions
func setup_audio_players() -> void:
	for genum in Genum.BusID.values():
		for i in range(audio_player_count_per_group):
			var player := AudioStreamPlayer.new()
			add_child(player)
			var bus_name : StringName = GenumHelper.BusName.get(genum)
			player.name = "AudioPlayer%s_Bus%s" % [i, bus_name]
			player.bus = bus_name
			if audio_players.has(genum):
				audio_players.get(genum).append(player)
			else:
				audio_players.set(genum, [player])
			
			player.finished.connect(_on_player_finished)

func add_sound(sound: AudioStream, bus: Genum.BusID = Genum.BusID.SFX) -> void:
	match(bus):
		Genum.BusID.SFX:
			sfx_pool.set(sound.resource_name.split(".")[0], sound)
		Genum.BusID.UI:
			ui_pool.set(sound.resource_name.split(".")[0], sound)
		Genum.BusID.AMBIENT:
			ambient_pool.set(sound.resource_name.split(".")[0], sound)
		_:
			push_warning("There's no such bus to subscribe to")

func remove_sound(sound: AudioStream, bus: Genum.BusID = Genum.BusID.SFX) -> void:
	if bus != Genum.BusID.SFX:
		match(bus):
			Genum.BusID.UI:
				ui_pool.erase(sound.resource_name.split(".")[0])
			Genum.BusID.AMBIENT:
				ambient_pool.erase(sound.resource_name.split(".")[0])
			_:
				push_warning("There's no such bus to unsubscribe from")
	else:
		var erased = false
		for pool in [sfx_pool, ui_pool, ambient_pool]:
			var sound_name := sound.resource_name.split(".")[0]
			if pool.has(sound_name):
				pool.erase(sound_name)
				pass
		push_warning("Sound doesn't exist in any subscribed bus")
#endregion

#region Usage Functions
func play_sound(sound_name: StringName) -> void:
	var sound := find_sound(sound_name)
	var player : AudioStreamPlayer
	if sound[1]:
		player = find_open_player(sound[1])
	
	if player:
		player.stream = sound[0]
		player.play()
		playing.append(sound_name)

func find_sound(sound_name: StringName) -> Array:
	var bus : Genum.BusID
	var sound : AudioStream
	if sfx_pool.has(sound_name):
		bus = Genum.BusID.SFX
		sound = sfx_pool.get(sound_name)
	elif ui_pool.has(sound_name):
		bus = Genum.BusID.UI
		sound = ui_pool.get(sound_name)
	elif ambient_pool.has(sound_name):
		bus = Genum.BusID.AMBIENT
		sound = ambient_pool.get(sound_name)
	
	return [sound, bus]

func find_sound_stringname(stream: AudioStream) -> StringName:
	if stream in sfx_pool.values():
		return sfx_pool.find_key(stream)
	elif stream in ui_pool.values():
		return ui_pool.find_key(stream)
	elif stream in ambient_pool.values():
		return ambient_pool.find_key(stream)
	
	push_warning("There is no stream '%s' found in any sound pool." % stream)
	return &""

func find_open_player(bus: Genum.BusID) -> AudioStreamPlayer:
	var player_list = audio_players.get(bus)
	for player in player_list:
		if not player.playing:
			return player
	
	push_warning("There is no open player...")
	return null 
#endregion

func _on_player_finished() -> void:
	for bus in audio_players:
		for player in audio_players.get(bus):
			if player.stream and not player.playing:
				playing.erase(find_sound_stringname(player.stream))
