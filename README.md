# Cursor Highlight

DMS daemon plugin that draws a click-through ring around the cursor on an overlay layer.
Useful for presentations and screen sharing - the ring is a normal Wayland surface, so it
is captured by screencopy even when the hardware cursor is not.

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

Ring radius, thickness, and color are configurable in DMS Settings → Plugins → Cursor Highlight.

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

The helper sidesteps Qt entirely: every 16ms it opens the socket, sends `cursorpos`,
prints the `x, y` reply to stdout, and closes. The QML side just parses stdout. If
Quickshell ever demotes the peer-close warning, the helper can be replaced with a
pure-QML `Socket` + `Timer`.
