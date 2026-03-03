extends Node

var commands: Dictionary = {}
const linestart = "| > "
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
var processing_enter: bool = false  # Flag to prevent race conditions
@export var folded: bool = true # console starts folded in
@export var commandSplitSymbol: String = " "
@export var lines : int = 15
const pixelsPerLine : int = 30

var starttext = ""
func _ready() -> void:
	for i in range(lines-2):
		starttext += " \n"
	text_edit.text = starttext + linestart
	$VBoxContainer/TextEdit.custom_minimum_size.y = pixelsPerLine * lines
	
	text_edit.gui_input.connect(_on_text_edit_input)
	
	attachGoofySyntaxHighlighter()

func attachGoofySyntaxHighlighter():
	# Register built-in commands
	register_command("clear", _cmd_clear)
	register_command("list", _cmd_list)
	
	# 1. Create the highlighter object
	var highlighter = CodeHighlighter.new()
	
	# 2. Define your color rules
	# syntax: add_keyword_color("word", Color.HEX_OR_NAME)
	highlighter.add_keyword_color("RED", Color.RED)
	
	# 3. Tell the TextEdit to use this highlighter
	$VBoxContainer/TextEdit.syntax_highlighter = highlighter

func register_command(command_name: String, callback: Callable) -> void:
	"""Register a new console command with a callback function"""
	if commands.has(command_name):
		log_warning("Overwriting existing command: '%s'" % command_name)
	
	commands[command_name] = callback
	print("Console: Registered command '%s'" % command_name)

func unregister_command(command_name: String) -> void:
	"""Remove a command from the registry"""
	if commands.erase(command_name):
		print("Console: Unregistered command '%s'" % command_name)
	else:
		log_warning("Command '%s' not found" % command_name)
func logInfo(message: String) -> void:
	"""Add a log message to the console"""
	text_edit.set_line(text_edit.get_line_count() - 1, "    " + message + "\n")
func log_error(message: String) -> void:
	"""Log an error message"""
	logInfo("[ERROR] " + message)
func log_warning(message: String) -> void:
	"""Log a warning message"""
	logInfo("[WARNING] " + message)

func _on_text_edit_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ENTER:
		if event.pressed:
			if not processing_enter:
				processing_enter = true
				handle_enter()
		else:
			processing_enter = false
		
		get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
	# Check for tilda input action to toggle console
	if event.is_action_pressed("tilda"):
		folded = !folded
		if folded:
			$AnimationPlayer.play("in")
			text_edit.release_focus()
		else:
			$AnimationPlayer.play("out")
			text_edit.grab_focus()
			# Set cursor to end of last line
			var last_line: int = text_edit.get_line_count() - 1
			var last_column: int = text_edit.get_line(last_line).length()
			text_edit.set_caret_line(last_line)
			text_edit.set_caret_column(last_column)
		get_viewport().set_input_as_handled()
func handle_enter() -> void:
	$VBoxContainer/TextEdit.scroll_vertical += 10000
	var current_line: int = text_edit.get_caret_line()
	var line_text: String = text_edit.get_line(current_line)
	var clean_command = line_text.substr(4) # shave off "| > " part
	
	text_edit.insert_text_at_caret("\n| > ")
	
	# Execute command if not empty
	if clean_command.strip_edges() != "":
		executeCommand(clean_command)
	
	# Wait a frame before allowing next enter
	await get_tree().process_frame
	processing_enter = false
func _process(delta: float) -> void:
	$VBoxContainer/TextEdit.scroll_vertical += delta*10
	
	if processing_enter:
		return
	
	# clean text
	var cleanedText = cleanText(text_edit.text)
	if text_edit.text != cleanedText:
		text_edit.text = cleanedText
		text_edit.set_caret_line(text_edit.get_line_count() - 1)
		text_edit.set_caret_column(text_edit.get_line(text_edit.get_line_count() - 1).length())
	
	var last_line: int = text_edit.get_line_count() - 1
	var current_line := text_edit.get_caret_line()
	var last_column: int = text_edit.get_line(last_line).length() - 1
	
	if last_line != current_line:
		text_edit.set_caret_line(last_line)
		text_edit.set_caret_column(last_column)
	
	if last_column < 3:
		text_edit.set_line(last_line,"| > ")
		last_column = text_edit.get_line(last_line).length() - 1
		text_edit.set_caret_column(last_column + 1)
func cleanText(text: String): # cleanes our text from all the icky symbols created by ^ + {letter}
	var cleaned = text.replace("â", "a").replace("Â", "A")
	cleaned = cleaned.replace("ê", "e").replace("Ê", "E")
	cleaned = cleaned.replace("î", "i").replace("Î", "I")
	cleaned = cleaned.replace("ô", "o").replace("Ô", "O")
	cleaned = cleaned.replace("û", "u").replace("Û", "U")
	cleaned = cleaned.replace("^","")
	return cleaned
func executeCommand(command: String):
	var splitString = command.split(commandSplitSymbol, false)
	
	if splitString.is_empty():
		return
	
	var operation: String = splitString[0].to_lower()
	#var parameters: Array = splitString.slice(1)
	
	# Check if command exists
	if not commands.has(operation):
		log_error("Unknown command: '%s'. Type 'list' for available commands." % operation)
		return
	
	# Execute the command
	var callback: Callable = commands[operation]
	
	# Call with parameters (for now, callback receives no args)
	# In the future you can pass parameters: callback.call(parameters)
	callback.call()
# Built-in commands
func _cmd_clear() -> void:
	text_edit.text = starttext + linestart
	var last_line: int = text_edit.get_line_count() - 1
	var last_column: int = text_edit.get_line(last_line).length()
	text_edit.set_caret_line(last_line)
	text_edit.set_caret_column(last_column)
func _cmd_list() -> void:
	logInfo("Available commands:")
	for cmd in commands.keys():
		logInfo("  - " + cmd)
