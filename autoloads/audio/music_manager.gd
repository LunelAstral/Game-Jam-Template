extends Node

#region Variable Definitions
var song_pool : Dictionary[StringName, Array]
var main_music_player : AudioStreamPlayer
var secondary_music_player : AudioStreamPlayer
var current_song : StringName
var crossfade := false
#endregion

#region Setup
func _ready() -> void:
	setup_music_players()

func _process(delta: float) -> void:
	if current_song != &"":
		if song_pool.get(current_song).get(1) != -1 and not crossfade:
			var current_pos = main_music_player.get_playback_position()
			if current_pos >= song_pool.get(current_song).get(1):
				main_music_player.seek(0)

func setup_music_players() -> void:
	main_music_player = AudioStreamPlayer.new()
	main_music_player.bus = GenumHelper.BusName.get(Genum.BusID.OST)
	add_child(main_music_player)
	
	secondary_music_player = AudioStreamPlayer.new()
	secondary_music_player.bus = GenumHelper.BusName.get(Genum.BusID.OST)
	add_child(secondary_music_player)

func add_ost(stream: AudioStream, loop: int) -> void:
	print("added %s" % stream.resource_name)
	song_pool.set(stream.resource_name, [stream, loop])

func remove_ost(stream_name: StringName) -> void:
	if song_pool.has(stream_name):
		song_pool.erase(stream_name)
	else:
		push_warning("There is no stream by %s in song_pool" % stream_name)
#endregion

#region Usage Functions
func play_song(song_name: StringName, crossover: bool = false) -> void:
	# TODO: Need to be able to loop the song as Yuvi describes, might need to change
	# how songs are loaded?
	if not song_pool.has(song_name):
		push_error("There's no song by the name %s in song_pool" % song_name)
	
	current_song = song_name
	if crossover:
		_crossover(song_name)
	else:
		main_music_player.stream = song_pool.get(song_name).get(0)
		main_music_player.play()

func _crossover(song_name: StringName, sfx_crossover := false) -> void:
	crossfade = true
	if !sfx_crossover:
		# Setup new song on secondary
		secondary_music_player.stream = song_pool.get(song_name).get(0)
		secondary_music_player.volume_linear = 0
		secondary_music_player.play()
		
		# Create the crossover tween
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
		tween.tween_property(main_music_player, "volume_linear", 0, 1.0)
		tween.parallel().tween_property(secondary_music_player, "volume_linear", 1, 1.0)
		tween.tween_callback(func(): tween.kill)
		
		await tween.finished
		# Move from secondary to main
		main_music_player.stream = secondary_music_player.stream
		main_music_player.volume_linear = 1
		secondary_music_player.volume_linear = 0
		main_music_player.play(secondary_music_player.get_playback_position())
		secondary_music_player.stop()
		secondary_music_player.stream = null
	elif sfx_crossover:
		# fade our main track, play our SFX, then fade back in
		var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_SINE)
		tween.tween_property(main_music_player, "volume_linear", 0, 5.0)
		await tween.finished
		SoundManager.play_sound(song_name)
		tween.tween_property(main_music_player, "volume_linear", 1, 5.0)
		await tween.finished
	
	crossfade = false

func play_jingle(sfx: StringName) -> void:
	# TODO: Need to crossfade with an ost to do the "jingle" that Yuvi needs
	if main_music_player.playing:
		_crossover(sfx, true)
	else : SoundManager.play_sound(sfx)

func stop_song() -> void:
	main_music_player.stop()
	current_song = &""
#endregion
