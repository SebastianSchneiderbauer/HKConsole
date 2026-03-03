# HKConsole

A lightweight in-game developer console for Godot 4. Toggle it open with `^`, type commands, and extend it with your own callbacks at runtime.

---

## Setup

1. **Add the scene** — Place `HKConsoleUI.tscn` somewhere in your project (e.g. `res://tools/HKConsole/`).

2. **Register as Autoload** — In `Project → Project Settings → Autoload`, add the scene as a global:

   | Name | Path |
   |------|------|
   | `HKConsole` | `res://tools/HKConsole/HKConsoleUI.tscn` |

3. **Add the input action** — In `Project → Project Settings → Input Map`, create an action named `tilda` and bind it to the `^` key. IMPORTANT: the action should be "AsciiCircum or QuoteLeft (Physical) or AsciiCircum (Unicode)"

---

## Usage

| Action | Result |
|--------|--------|
| `~` | Toggle console open / closed |
| `Enter` | Execute the typed command |
| `list` | Print all registered commands |
| `clear` | Clear the console output |

### Registering Commands

From any script, call:

```gdscript
HKConsole.register_command("my_command", _my_callback)

func _my_callback() -> void:
    HKConsole.logInfo("Hello from my_command!")
```

### Logging

```gdscript
HKConsole.logInfo("Some info")
HKConsole.log_warning("Something looks off")
HKConsole.log_error("Something broke")
```

---

## Exports

| Property | Default | Description |
|----------|---------|-------------|
| `folded` | `true` | Start with the console hidden |
| `commandSplitSymbol` | `" "` | Delimiter between command and args (not yet implemented)|
| `lines` | `15` | Visible line count, aka the height of the console|

---

## Customization

To change the look, add child nodes to the `TextEdit` node in the scene — similar to the two background `Label` nodes already present.
