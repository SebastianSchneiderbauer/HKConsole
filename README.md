# HKConsole

A lightweight in-game developer console for Godot 4. Toggle it open with `^`, type commands, and extend it with your own callbacks at runtime. 
<img src="https://github.com/user-attachments/assets/98ede130-c703-4ffe-bb83-d2d22ab9c3e9" alt="Description" width="100%">
## Setup

1. **Add the scene** — Place `HKConsoleUI.tscn` somewhere in your project (e.g. `res://tools/HKConsole/`).

2. **Register as Autoload** — In `Project → Project Settings → Autoload`, add the scene as a global:

   | Name | Path |
   |------|------|
   | `HKConsole` | `res://tools/HKConsole/HKConsoleUI.tscn` |

3. **Add the input actions** — In `Project → Project Settings → Input Map`, create the following actions. The names must match **exactly**, otherwise the console won't pick them up:

   | Action name | Bind to | Notes |
   |-------------|---------|-------|
   | `tilda` | `^` key | IMPORTANT: the action should be "AsciiCircum or QuoteLeft (Physical) or AsciiCircum (Unicode)" |
   | `mouseWhUp` | Mouse Wheel Up | Scrolls the console output up while it's open |
   | `mouseWhDown` | Mouse Wheel Down | Scrolls the console output down while it's open |

---

## Usage

| Action | Result |
|--------|--------|
| `^` | Toggle console open / closed |
| `Enter` | Execute the typed command |
| `list` | Print all registered (non-secret) commands |
| `list -all` | Print all registered commands including secret ones |
| `clear` | Clear the console output |
| `exit` | Closes the terminal, since closing per `^` does not work on linux rn |

### Registering Commands

```gdscript
HKConsole.register_command(command_name: String, callback: Callable, secret: bool, isCheat: bool = false)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `command_name` | `String` | The string the user types to invoke the command |
| `callback` | `Callable` | The function to call when the command is executed |
| `secret` | `bool` | If `true`, the command is hidden from `list` (still visible via `list -all`) |
| `isCheat` | `bool` | If `true`, the command can only be executed while cheat mode is active |

The console checks how many arguments the callback declares and dispatches accordingly:

- **No parameters** — declare the function with **no arguments**. Any arguments the user types will be silently ignored. Do **not** add a `params` argument "just in case" — that would switch it into parameter-receiving mode.
- **With parameters** — declare the function with exactly **one `params: Array` argument**. Arguments typed after the command name are split on `commandSplitSymbol` (default: space) and forwarded as that array.

Use `HKConsole.checkParameters(params, needed, allowed)` to validate the received parameters. It returns `false` if any entry in `needed` is missing from `params`, or if `params` contains a value not listed in `allowed`.

```gdscript
HKConsole.checkParameters(params: Array, needed: Array, allowed: Array) -> bool
```

| Parameter | Description |
|-----------|-------------|
| `params` | The array received by the callback |
| `needed` | Flags that **must** be present |
| `allowed` | All flags that are permitted (superset of `needed`) |

```gdscript
# Command that takes no console parameters — NO function argument
HKConsole.register_command("my_command", _my_callback, false)

func _my_callback() -> void:
	HKConsole.logInfo("Hello from my_command!")

# Command with an optional flag — e.g. "status -v"
HKConsole.register_command("status", _cmd_status, false)

func _cmd_status(params: Array) -> void:
	if not HKConsole.checkParameters(params, [], ["-v"]):
		HKConsole.logError("Usage: status [-v]")
		return
	HKConsole.logInfo("OK")
	if params.has("-v"):
		HKConsole.logInfo("verbose details here...")

# Secret command — hidden from list, visible via list -all
HKConsole.register_command("my_debug_cmd", _my_debug, true)

# Cheat command — only executable when cheat mode is active
HKConsole.register_command("god_mode", _god_mode, false, true)
```

### Logging

```gdscript
HKConsole.logInfo("Some info")
HKConsole.logWarning("Something looks off")
HKConsole.logError("Something broke")
```

---

## Exports

| Property | Default | Description |
|----------|---------|-------------|
| `folded` | `true` | Start with the console hidden |
| `commandSplitSymbol` | `" "` | Delimiter between command name and its arguments |
| `lines` | `15` | Visible line count, aka the height of the console |
| `max_history` | `50` | Number of previously entered commands kept in history |
| `cheatConfig` | `null` | Optional `HKConsoleCheatConfig` resource — enables cheat mode support |
| `cheatMode` | `false` | Whether cheat mode starts enabled |

### Cheat Mode

Cheat mode restricts access to commands registered with `isCheat = true`. It is toggled by a special activation command defined in a `HKConsoleCheatConfig` resource.

**To enable cheat mode:**

1. Create a `HKConsoleCheatConfig` resource and assign it to the `cheatConfig` export on the console node.
2. Commands registered with `isCheat = true` will be locked until cheat mode is activated.
3. The user activates cheat mode by running the `cheatActivationString` command (default: `IDKFA`). Running it again deactivates it.

**`HKConsoleCheatConfig` properties:**

| Property | Default | Description |
|----------|---------|-------------|
| `cheatActivationString` | `"IDKFA"` | The command that toggles cheat mode on/off |
| `splitSymbol` | `"\|"` | Separator used to split the activation/deactivation messages into multiple lines |
| `onActivateString` | `"CHEATS ARE ACTIVATED\|..."` | Message printed when cheats are activated (split by `splitSymbol`) |
| `onDeactivateString` | `"CHEATS ARE DEACTIVATED\|..."` | Message printed when cheats are deactivated (split by `splitSymbol`) |

---

## Customization

To change the look, add child nodes to the `TextEdit` node in the scene — similar to the two background `Label` nodes already present.
