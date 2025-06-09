extends CanvasLayer

#region Variables
@export var text_box : TextEdit
@export var text_line : LineEdit

var text : String = "Debug Terminal"
#endregion

#region Built-Ins
func _ready() -> void:
	text_box.set_line(0, text)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug"):
		if visible:
			hide()
		else:
			show()
#endregion

#region Private Methods
func _add_line(new_text: String) -> void:
	text_box.set_line(text_box.get_line_count(), new_text)
#endregion

#region Signal Callbacks
func _on_text_submit(new_text: String) -> void:
	text_line.text = ""
	if new_text[0] == "/":
		var command_text := new_text.split("/")[1]
		var command := command_text.split(" ")
		var command_name := command[0]
		var args : Array[String] = []
		if command.size() > 1:
			args = command.slice(1)
		
		if self.has_method(command_name):
			var callable = Callable(self, command_name)
			callable.call(args)
		else:
			_add_line("There is no command by the name %s" % command_name)
	else:
		_add_line("That was not a command, please use /")
	
	text_box.text = text
	text_box.scroll_vertical = text_box.get_line_count() - 1
#endregion

#region Commands
func help(args: Array[String]) -> void:
	if args.size() == 0:
		var command_list : Array[String] = [
			"help"
		]
		
		_add_line("List of Available Commands:")
		for command in command_list:
			_add_line("%s" % command)
#endregion
