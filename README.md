# Cursor Highlight

DMS daemon plugin that draws a click-through highlight (ring, dot, or arrow) at the
cursor on an overlay layer. Useful for presentations and screen sharing - the highlight
is a normal Wayland surface, so it is captured by screencopy even when the hardware
cursor is not.

Hyprland only. Requires `python3` (see [Why the python3 helper?](#why-the-python3-helper) below).

## Install

```bash
ln -s ~/Projects/cursor-highlight ~/.config/DankMaterialShell/plugins/cursor-highlight
```

Then: DMS Settings → Plugins → Scan for Plugins → enable Cursor Highlight.

## Usage

```bash
dms ipc call cursorHighlight toggle   # also: enable / disable
```

Example Hyprland bind:

```ini
bindd = SUPER, F10, Toggle cursor highlight, exec, dms ipc call cursorHighlight toggle
```

Highlight style (ring, dot, or arrow), size, color, and polling rate are configurable
in DMS Settings → Plugins → Cursor Highlight.

## Development

After editing plugin files, restart DMS to pick up the changes:

```bash
dms restart
```

Why: the QML engine caches compiled components by file URL for the lifetime of the
process, and DMS's plugin reload only cache-busts the daemon component
(`CursorHighlight.qml`) - the settings panel (`CursorHighlightSettings.qml`) is loaded
by plain URL and stays cached until the shell restarts. The cache also stores failures:
if the settings file is missing or broken on first open, the panel silently stays empty
on every later attempt until a restart, with nothing in the log.

`dms ipc call plugins reload cursorHighlight` is enough if only `CursorHighlight.qml`
changed; when in doubt, `dms restart`.

## Why the python3 helper?

The plugin polls the cursor position from Hyprland's IPC socket - the same request
`hyprctl cursorpos` makes. A small long-lived python3 process does this instead of a
QML `Socket`, for one reason: log noise.

Hyprland's IPC serves one request per connection and then closes it - the close is the
normal end-of-response marker. Qt, however, reports any connection ending the client
didn't initiate through its error signal (`PeerClosedError`), because it can't know
whether a server hang-up is expected for the protocol. Quickshell then logs every such
error as a warning in C++, before QML code gets a chance to filter it. Polling at 60Hz
from QML therefore floods the Quickshell log with ~60 meaningless warnings per second,
and nothing in QML can suppress them.

The helper sidesteps Qt entirely: at the configured polling rate (60Hz by default) it opens the socket, sends `cursorpos`,
prints the `x, y` reply to stdout, and closes. The QML side just parses stdout. If
Quickshell ever demotes the peer-close warning, the helper can be replaced with a
pure-QML `Socket` + `Timer`.
