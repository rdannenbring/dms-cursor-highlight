import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool active: false

    // Used by PluginService.togglePlugin()
    function toggle() {
        active = !active;
    }

    readonly property real ringRadius: pluginData.ringRadius || 28
    readonly property real ringThickness: pluginData.ringThickness || 4
    readonly property color ringColor: pluginData.ringColor || Theme.primary
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
                x: win.localX - width / 2
                y: win.localY - height / 2
                width: root.ringRadius * 2
                height: root.ringRadius * 2
                radius: root.ringRadius
                color: "transparent"
                border.color: root.ringColor
                border.width: root.ringThickness
            }
        }
    }
}
