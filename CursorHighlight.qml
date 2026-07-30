import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool active: false

    readonly property real ringRadius: pluginData.ringRadius || 28
    readonly property real ringThickness: pluginData.ringThickness || 4
    readonly property color ringColor: pluginData.ringColor || Theme.primary

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

    // Hyprland answers one request per connection, then closes it;
    // the timer reconnects every tick.
    Socket {
        id: hyprSocket

        path: Hyprland.requestSocketPath

        parser: SplitParser {
            // Replies have no trailing newline; empty marker emits raw chunks
            splitMarker: ""
            onRead: data => {
                const parts = data.split(",");
                if (parts.length === 2) {
                    root.cursorX = parseInt(parts[0]);
                    root.cursorY = parseInt(parts[1]);
                }
            }
        }

        onConnectedChanged: {
            if (connected) {
                write("cursorpos");
                flush();
            }
        }

        onError: error => {
            // 1 = QLocalSocket::PeerClosedError, expected after every reply
            if (error !== 1 && root.active) {
                root.active = false;
                console.warn("CursorHighlight: Hyprland IPC error", error, "- disabling");
            }
        }
    }

    Timer {
        running: root.active
        interval: 16
        repeat: true
        triggeredOnStart: true
        onTriggered: hyprSocket.connected = true
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
