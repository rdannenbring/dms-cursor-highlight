import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "cursorHighlight"

    readonly property var daemonInstance: pluginService && pluginService.pluginDaemonInstances ? pluginService.pluginDaemonInstances[pluginId] : null
    readonly property bool ringActive: daemonInstance ? daemonInstance.active : false

    StyledText {
        text: "Cursor Highlight"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: "Click-through ring around the cursor for presentations and screen sharing. Toggle with: dms ipc call cursorHighlight toggle"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
    }

    DankToggle {
        width: parent.width
        text: "Show Ring"
        description: "Same as: dms ipc call cursorHighlight toggle"
        checked: root.ringActive
        onToggled: isChecked => {
            if (root.daemonInstance)
                root.daemonInstance.active = isChecked;
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    SliderSetting {
        settingKey: "ringRadius"
        label: "Ring Radius"
        description: "Radius of the highlight ring"
        defaultValue: 28
        minimum: 8
        maximum: 100
        unit: "px"
        rightIcon: "radio_button_unchecked"
    }

    SliderSetting {
        settingKey: "ringThickness"
        label: "Ring Thickness"
        description: "Border width of the ring"
        defaultValue: 4
        minimum: 1
        maximum: 20
        unit: "px"
        rightIcon: "line_weight"
    }

    SliderSetting {
        settingKey: "pollRate"
        label: "Polling Rate"
        description: "How often the cursor position is sampled. Higher is smoother, slightly more CPU"
        defaultValue: 60
        minimum: 10
        maximum: 240
        unit: "Hz"
        rightIcon: "speed"
    }

    ColorSetting {
        id: colorSetting
        settingKey: "ringColor"
        label: "Ring Color"
        description: "Defaults to the theme primary color"
        defaultValue: Theme.primary
    }

    DankButton {
        text: "Reset Color to Theme Default"
        iconName: "format_color_reset"
        onClicked: {
            // Remove the stored value entirely (instead of saving the current
            // theme color as a fixed hex) so the ring keeps following the theme
            colorSetting.isInitialized = false;
            colorSetting.value = colorSetting.defaultValue;
            root.saveValue("ringColor", undefined);
            colorSetting.isInitialized = true;
        }
    }
}
