extends Control

var commands: Dictionary = {}
const linestart = " made by HerrKleiderbauer\n HKConsole "+version+" "
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
var processing_enter: bool = false  # Flag to prevent race conditions
@export var folded: bool = true # console starts folded in
@export var commandSplitSymbol: String = " "
@export var lines : int = 15
const pixelsPerLine : int = 30

const version : String = "v1.1.2"

var command_history: Array[String] = []
var history_index: int = -1  # -1 = not navigating
var history_draft: String = ""  # saves current input when navigation starts
@export var max_history: int = 50

var previous_text_length: int = 0  # Track text changes for auto-scroll

var starttext = ""

# Log delay system
@export var log_delay: float = 0.05  # Delay in seconds between each log line

func scroll_to_bottom() -> void:
	"""Scroll the console to the bottom"""
	text_edit.set_v_scroll(99999)  # Set to very high value to ensure bottom

func _scroll_up() -> void:
	"""Scroll the console view up smoothly"""
	var current_scroll = text_edit.get_v_scroll()
	text_edit.set_v_scroll(max(0, current_scroll - 1))

func _scroll_down() -> void:
	"""Scroll the console view down smoothly"""
	var current_scroll = text_edit.get_v_scroll()
	text_edit.set_v_scroll(current_scroll + 1)

func _ready() -> void:
	for i in range(lines-2):
		starttext += " \n"
	text_edit.text = starttext + linestart
	previous_text_length = text_edit.text.length()  # Initialize text length tracker
	$VBoxContainer/TextEdit.custom_minimum_size.y = pixelsPerLine * lines

	text_edit.gui_input.connect(_on_text_edit_input)

	register_command("list",_cmd_list)
	register_command("clear",_cmd_clear)
	register_command("exit",_cmd_exit)

func register_command(command_name: String, callback: Callable) -> void:
	"""Register a new console command with a callback function"""
	if commands.has(command_name):
		push_warning("Overwriting existing command: '%s'" % command_name)
	
	commands[command_name] = callback
	print("Console: Registered command '%s'" % command_name)

func unregister_command(command_name: String) -> void:
	"""Remove a command from the registry"""
	if commands.erase(command_name):
		print("Console: Unregistered command '%s'" % command_name)
	else:
		logWarning("Command '%s' not found" % command_name)
func logInfo(message: String) -> void:
	"""Add a log message to the console with delay"""
	# Display the message immediately
	text_edit.set_line(text_edit.get_line_count() - 1, "    " + message + "\n")
	scroll_to_bottom()

	# Wait for delay before allowing next message
	await get_tree().create_timer(log_delay).timeout

func logError(message: String) -> void:
	"""Log an error message"""
	logInfo("[ERROR] " + message)
func logWarning(message: String) -> void:
	"""Log a warning message"""
	logInfo("[WARNING] " + message)

func _on_text_edit_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			if not processing_enter:
				processing_enter = true
				handle_enter()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			_history_up()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_history_down()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_ENTER:
		processing_enter = false
		get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
	# Check for scroll wheel events when console is open
	if not folded and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_up()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_down()
			get_viewport().set_input_as_handled()

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
			scroll_to_bottom()  # Scroll to bottom when opening console
		get_viewport().set_input_as_handled()
func handle_enter() -> void:
	var current_line: int = text_edit.get_caret_line()
	var line_text: String = text_edit.get_line(current_line)
	var clean_command = line_text.substr(13 + version.length()) # shave off " HKConsole {version} " part

	text_edit.insert_text_at_caret("\n| > ")
	scroll_to_bottom()  # Scroll to bottom when command is entered

	# Save to history and execute
	if clean_command.strip_edges() != "":
		command_history.append(clean_command)
		if command_history.size() > max_history:
			command_history.pop_front()
		executeCommand(clean_command)

	history_index = -1  # reset navigation on enter

	# Wait a frame before allowing next enter
	await get_tree().process_frame
	processing_enter = false
@export var ypos : float # used for naimating only the y of the vbox without touching x
func _history_up() -> void:
	if command_history.is_empty():
		return
	var last_line = text_edit.get_line_count() - 1
	if history_index == -1:
		history_draft = text_edit.get_line(last_line).substr(19)
		history_index = command_history.size() - 1
	elif history_index > 0:
		history_index -= 1
	_set_history_line(command_history[history_index])

func _history_down() -> void:
	if history_index == -1:
		return
	if history_index < command_history.size() - 1:
		history_index += 1
		_set_history_line(command_history[history_index])
	else:
		history_index = -1
		_set_history_line(history_draft)

func _set_history_line(cmd: String) -> void:
	var last_line = text_edit.get_line_count() - 1
	text_edit.set_line(last_line, " HKConsole " + version + "> " + cmd)
	text_edit.set_caret_line(last_line)
	text_edit.set_caret_column(text_edit.get_line(last_line).length())

func _process(delta: float) -> void:
	if processing_enter:
		return

	# Auto-scroll to bottom when user types (text length changes)
	var current_text_length = text_edit.text.length()
	if current_text_length != previous_text_length:
		scroll_to_bottom()
		previous_text_length = current_text_length

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
	
	if last_column < 18:
		text_edit.set_line(last_line, " HKConsole " + version + "> ")
		last_column = text_edit.get_line(last_line).length() - 1
		text_edit.set_caret_column(last_column + 1)
		
	
	$VBoxContainer.custom_minimum_size.x = get_window().content_scale_size.x + 20
	$VBoxContainer.position.x = -5 * (1920/float(get_window().content_scale_size.x))
	$VBoxContainer.position.y = ypos
	
	$VBoxContainer/TextEdit.custom_minimum_size.y = pixelsPerLine * lines * (float(get_window().content_scale_size.y)/1080)
	
	$VBoxContainer/TextEdit.custom_minimum_size.x = get_window().size.x * 2
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
		logError("Unknown command: '%s'. Type 'list' for available commands." % operation)
		return
	
	# Execute the command
	var callback: Callable = commands[operation]
	
	# Call with parameters (for now, callback receives no args)
	# In the future you can pass parameters: callback.call(parameters)
	callback.call()
# Built-in commands
func _cmd_clear() -> void:
	text_edit.text = starttext + linestart
	previous_text_length = text_edit.text.length()  # Update text length tracker
	var last_line: int = text_edit.get_line_count() - 1
	var last_column: int = text_edit.get_line(last_line).length()
	text_edit.set_caret_line(last_line)
	text_edit.set_caret_column(last_column)
	scroll_to_bottom()
func _cmd_list() -> void:
	await logInfo("Available commands:")
	for cmd in commands.keys():
		await logInfo("  - " + cmd)
func _cmd_exit() -> void:
	folded = true
	$AnimationPlayer.play("in")
	text_edit.release_focus()
