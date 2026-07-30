import QtQuick
import Quickshell
import qs.Common

QtObject {
    function check(done) {
        if (!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
            done({
                title: "Hyprland is required",
                details: "Cursor Highlight reads the cursor position from Hyprland's IPC socket and does not work on other compositors."
            });
            return;
        }
        Proc.runCommand("cursorHighlight.startupCheck", ["sh", "-c", "command -v python3 >/dev/null 2>&1"], (stdout, exitCode) => {
            if (exitCode === 0) {
                done(null);
                return;
            }
            done({
                title: "python3 is required",
                details: "Install python3, then enable the plugin again. See the README for why it is needed."
            });
        });
    }
}
