import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool active: false

    // Forget the stale position from last time, so the highlight stays hidden
    // until the first fresh poll instead of flashing at the old location
    onActiveChanged: {
        if (active) {
            cursorX = -1;
            cursorY = -1;
        }
    }

    // Used by PluginService.togglePlugin()
    function toggle() {
        active = !active;
    }

    readonly property string highlightStyle: pluginData.style || "ring"
    readonly property real highlightSize: pluginData.size || 28
    readonly property real highlightThickness: pluginData.thickness || 4
    readonly property color highlightColor: pluginData.color || Theme.primary
    readonly property real offsetX: pluginData.offsetX || 0
    readonly property real offsetY: pluginData.offsetY || 0
    readonly property real pollRate: pluginData.pollRate || 60

    // Process only picks up a new command on restart
    onPollRateChanged: {
        if (poller.running) {
            poller.running = false;
            poller.running = Qt.binding(() => root.active);
        }
    }

    // Global layout coordinates, -1 until first poll
    property real cursorX: -1
    property real cursorY: -1

    // Bind with: dms ipc call cursorHighlight toggle
    IpcHandler {
        target: "cursorHighlight"

        function toggle(): string {
            root.active = !root.active;
            return root.active ? "enabled" : "disabled";
        }

        function enable(): string {
            root.active = true;
            return "enabled";
        }

        function disable(): string {
            root.active = false;
            return "disabled";
        }
    }

    // Cursor position poller.
    //
    // Hyprland's IPC socket serves exactly one request per connection and then
    // closes it. Polling it with a QML Socket therefore ends every poll with a
    // peer-close, which Quickshell logs as a PeerClosedError warning from C++
    // (~60/sec, not suppressible from QML). Spawning `hyprctl` per poll avoids
    // that but forks a process 60x/sec.
    //
    // Instead, one long-lived python3 helper does what hyprctl does internally:
    // every 16ms it opens the socket, sends "cursorpos", prints the "x, y"
    // reply to stdout, and closes. The SplitParser below feeds each line back
    // into cursorX/cursorY. If Quickshell ever demotes the peer-close warning,
    // this can go back to a pure-QML Socket + Timer.
    Process {
        id: poller

        running: root.active
        command: ["python3", "-c", "import os,socket,time\n" + "p=os.path.join(os.environ['XDG_RUNTIME_DIR'],'hypr',os.environ['HYPRLAND_INSTANCE_SIGNATURE'],'.socket.sock')\n" + "while True:\n" + " s=socket.socket(socket.AF_UNIX)\n" + " s.connect(p)\n" + " s.sendall(b'cursorpos')\n" + " d=s.recv(64)\n" + " s.close()\n" + " print(d.decode(),flush=True)\n" + " time.sleep(" + (1 / root.pollRate).toFixed(4) + ")"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(",");
                if (parts.length === 2) {
                    root.cursorX = parseInt(parts[0]);
                    root.cursorY = parseInt(parts[1]);
                }
            }
        }

        onExited: {
            if (root.active) {
                root.active = false;
                console.warn("CursorHighlight: poller died, disabling");
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            readonly property real localX: root.cursorX - modelData.x
            readonly property real localY: root.cursorY - modelData.y
            readonly property bool cursorOnScreen: localX >= 0 && localY >= 0 && localX < modelData.width && localY < modelData.height
            // Highlight anchor point, user offset applied
            readonly property real drawX: localX + root.offsetX
            readonly property real drawY: localY + root.offsetY

            screen: modelData
            visible: root.active && cursorOnScreen
            color: "transparent"
            WlrLayershell.namespace: "dms:cursor-highlight"
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Empty input region = click-through
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                visible: root.highlightStyle === "ring"
                x: win.drawX - width / 2
                y: win.drawY - height / 2
                width: root.highlightSize * 2
                height: root.highlightSize * 2
                radius: root.highlightSize
                color: "transparent"
                border.color: root.highlightColor
                border.width: root.highlightThickness
            }

            Rectangle {
                visible: root.highlightStyle === "dot"
                x: win.drawX - width / 2
                y: win.drawY - height / 2
                width: root.highlightSize * 2
                height: root.highlightSize * 2
                radius: root.highlightSize
                color: root.highlightColor
            }

            // Pointer-style arrowhead, tip at the cursor position, rotated
            // clockwise to match the default cursor's slightly-off-vertical lean
            Canvas {
                visible: root.highlightStyle === "arrow"
                x: win.drawX - width * 0.15
                y: win.drawY
                width: root.highlightSize * 2
                height: root.highlightSize * 2

                // Canvas only repaints on resize by itself
                property color paintColor: root.highlightColor
                onPaintColorChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.save();
                    ctx.clearRect(0, 0, width, height);
                    const s = width * 0.85;
                    ctx.fillStyle = paintColor;
                    // Tip sits inset from the left edge so the rotated body stays in bounds
                    ctx.translate(width * 0.15, 0);
                    ctx.rotate(23 * Math.PI / 180);
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(s * 0.9, s * 0.35);
                    ctx.lineTo(s * 0.55, s * 0.55);
                    ctx.lineTo(s * 0.35, s * 0.9);
                    ctx.closePath();
                    ctx.fill();
                    ctx.restore();
                }
            }
        }
    }
}
