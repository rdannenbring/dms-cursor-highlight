# Cursor Highlight

DMS daemon plugin that draws a click-through ring around the cursor on an overlay layer.
Useful for presentations and screen sharing — the ring is a normal Wayland surface, so it
is captured by screencopy even when the hardware cursor is not.

Hyprland only (polls `cursorpos` over the Hyprland IPC socket).

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

## Configuration

Optional keys in the plugin's settings (DMS plugin data), all with defaults:

| Key | Default | |
|---|---|---|
| `ringRadius` | `28` | ring radius in px |
| `ringThickness` | `4` | border width in px |
| `ringColor` | theme primary | any QML color string |
